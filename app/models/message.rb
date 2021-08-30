# == Schema Information
#
# Table name: messages
#
#  id                           :integer          not null, primary key
#  title                        :text
#  caption                      :text
#  type                         :string(255)
#  channel_id                   :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  content_file_name            :string(255)
#  content_content_type         :string(255)
#  content_file_size            :integer
#  content_updated_at           :datetime
#  seq_no                       :integer
#  next_send_time               :datetime
#  primary                      :boolean
#  reminder_message_text        :text
#  reminder_delay               :integer
#  repeat_reminder_message_text :text
#  repeat_reminder_delay        :integer
#  number_of_repeat_reminders   :integer
#  options                      :text
#  deleted_at                   :datetime
#  schedule                     :text
#  active                       :boolean
#  requires_response            :boolean
#  recurring_schedule           :text
#

class Message < ApplicationRecord
  include RelativeSchedule
  include IceCube

  scope :primary, -> { where(primary: true) }
  scope :secondary, -> { where(primary: false) }
  scope :active, -> { where(active: true) }
  scope :not_too_old, -> { where("next_send_time >= ?", 3.hours.ago) }
  scope :pending_send, -> { active.not_too_old.where("next_send_time <= ?", Time.current) }

  belongs_to :channel

  has_many :delivery_notices
  has_many :subscriber_responses
  has_many :response_actions
  has_many :message_options

  has_one :action, as: :actionable

  validates :seq_no, uniqueness: {
    scope: %i(channel_id deleted_at),
  }
  validates :type, presence: true, inclusion: {
    in: %w(ActionMessage PollMessage ResponseMessage SimpleMessage TagMessage),
  }
  validates_associated :action
  validate :check_relative_schedule

  before_create :update_seq_no
  after_create :after_create_cb
  before_validation :form_schedule

  accepts_nested_attributes_for(
    :message_options,
    reject_if: -> (a) { a[:key].blank? || a[:value].blank? },
    allow_destroy: true,
  )
  accepts_nested_attributes_for :action

  has_attached_file :content,
                    storage: :s3,
                    s3_credentials: {
                      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
                      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
                    },
                    s3_region: ENV["AWS_REGION"],
                    styles: {
                      thumb: { geometry: "100x100>", format: "jpg" },
                    }

  acts_as_paranoid

  serialize :options, Hash
  serialize :recurring_schedule, Hash

  after_initialize do |message|
    if message.new_record?
      begin
        message.type ||= "SimpleMessage"
        message.primary = true if message.primary.nil?
        message.reminder_delay ||= 1
        message.repeat_reminder_delay ||= 30
        message.number_of_repeat_reminders ||= 1
        message.active = true if message.active.nil?
        message.requires_response ||= false
      rescue ActiveModel::MissingAttributeError => e
        raise e.message
      end
    end
  end

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Message.model_name
      end
    end

    super
  end

  def self.child_classes
    self.validators
      .find { |v|
        v.attributes == [:type] && v.kind_of?(ActiveModel::Validations::InclusionValidator)
      }
      .options[:in]
      .map(&:constantize)
  end

  def self.my_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      find_each { |message| csv << message.attributes.values_at(*column_names) }
    end
  end

  def self.import(channel, file)
    CSV.foreach(file.path, headers: true) do |row|
      message = channel.messages.find(row["id"]) || channel.messages.new
      message.attributes = row.to_h.slice(*accessible_attributes)
      Rails.logger.info message.inspect
      message.save!
    end
  end

  def reset_next_send_time
    self.next_send_time = Time.current
    save!
  end

  def broadcast
    MessagingManagerWorker.perform_async "broadcast_message", "message_id" => id
  end

  def move_up
    current_seq_no = seq_no
    prev_seq_no = channel.messages.where("seq_no < ?", current_seq_no).maximum(:seq_no)

    if prev_seq_no
      prev_message = channel.messages.where(seq_no: prev_seq_no).first
      ActiveRecord::Base.transaction do
        self.seq_no = 0
        save!
        prev_message.seq_no = current_seq_no
        prev_message.save!
        self.seq_no = prev_seq_no
        save!
      end
    end

    true
  end

  def move_down
    current_seq_no = seq_no
    next_seq_no = channel.messages.where("seq_no > ?", current_seq_no).minimum(:seq_no)

    if next_seq_no
      next_message = channel.messages.where(seq_no: next_seq_no).first
      ActiveRecord::Base.transaction do
        self.seq_no = 0
        save!
        next_message.seq_no = current_seq_no
        next_message.save!
        self.seq_no = next_seq_no
        save!
      end
    end

    true
  end

  def perform_post_send_ops(subscribers)
    ssmc = SecondaryMessagesChannel.find_by(name: "_system_smc")
    unless ssmc
      SecondaryMessagesChannel.create! name: "_system_smc", tparty_keyword: "_system_smc"
      ssmc = SecondaryMessagesChannel.find_by(name: "_system_smc")
    end

    if requires_user_response? && reminder_message_text.present? && reminder_delay > 0
      message_text = reminder_message_text
      message_text << " #{channel.suffix}" if channel.suffix.present?

      reminder_message = ssmc.messages.create(
        caption: message_text,
        next_send_time: Time.current + reminder_delay * 60,
        primary: false,
        options: {
          message_id: id,
          channel_id: channel.id,
          subscriber_ids: subscribers.map(&:id),
          tparty_keyword: channel.tparty_keyword,
          reminder_message: true,
        },
      )
      reminder_message.save!
    end

    if requires_user_response? && repeat_reminder_message_text.present? &&
       repeat_reminder_delay > 0 && number_of_repeat_reminders > 0

      (1..number_of_repeat_reminders).each do |index|
        message_text = repeat_reminder_message_text
        message_text << " #{channel.suffix}" if channel.suffix.present?

        repeat_reminder_message = ssmc.messages.create(
          caption: message_text,
          primary: false,
          next_send_time: Time.current + repeat_reminder_delay * index * 60,
          options: {
            message_id: id,
            channel_id: channel.id,
            subscriber_ids: subscribers.map(&:id),
            tparty_keyword: channel.tparty_keyword,
            repeat_reminder_message: true,
          },
        )
        repeat_reminder_message.save!
      end
    end

    specialized_post_send_ops subscribers
  end

  def grouped_responses
    return [] if subscriber_responses.size < 1

    content_hash = {}
    s_responses = subscriber_responses.order(:created_at)

    s_responses.find_each do |s_response|
      content_hash[s_response.content_text] ||= {
        subscriber_responses: [],
        subscribers: [],
      }
      content_hash[s_response.content_text][:subscriber_responses] << s_response
      content_hash[s_response.content_text][:subscribers] << s_response.subscriber
    end

    ret = []
    content_hash.each do |content_message, rec|
      ret << {
        message_content: content_message,
        subscriber_responses: rec[:subscriber_responses],
        subscribers: rec[:subscribers].uniq,
      }
    end

    ret.sort! { |x, y| x[:message_content] <=> y[:message_content] }
  end

  # Abstract method
  def type_abbr
    raise NotImplementedError
  end

  # Messages that require user to send back a response
  def requires_user_response?
    false
  end

  # Messages that do action on user response
  def has_action_on_user_response?
    false
  end

  # Messages that handle broadcast themselves
  def internal?
    false
  end

  def send_to_subscribers(subscribers); end

  def process_subscriber_response(_sr)
    true
  end

  def specialized_post_send_ops(subscribers); end

  # simpler accessor for the id we are sending this mess THROUGH
  def tparty_identifier
    tpi = nil
    tpi = self.channel&.channel_group&.tparty_keyword unless !tpi.blank?
    tpi = self.channel&.tparty_keyword
    tpi
  end

  def recurring_schedule=(new_rule)
    self[:recurring_schedule] =
      if new_rule != "{}" && new_rule != "null" && RecurringSelect.is_valid_rule?(new_rule)
        RecurringSelect.dirty_hash_to_rule(new_rule).to_hash
      end
  end

  def update_next_send_time_for_recurring_schedule
    if recurring_schedule.present?
      msg_schedule = Schedule.new(Time.current)
      msg_schedule.add_recurrence_rule RecurringSelect.dirty_hash_to_rule(recurring_schedule)
      if msg_schedule.to_s == "Daily"
        self.next_send_time = (Time.current + 1.day).change(hour: rand(9..17), min: rand(0..59))
      else
        self.next_send_time = msg_schedule.next_occurrence(Time.current) if msg_schedule
      end
    end
  end

  def self.responding_message_types
    %w( PollMessage ResponseMessage )
  end

  private

    def self.import(channel,file)
      error_message = nil
      csv_string = File.read(file.path).scrub
      CSV.parse(csv_string, headers:true) do |row|
        message = channel.messages.find_by_id(row["id"]) || channel.messages.new
        hash_row = row.to_h
        hash_row.keys.each do |key|
          message[key] = hash_row[key] unless ["options"].include?(key)
        end
        message.channel_id = channel.id
        message.created_at = Time.current
        message.updated_at = Time.current
        Rails.logger.info message.inspect
      end
      { completed: true, message: nil }
    rescue => e
      { completed: false, message: e.message }
    end

    def update_seq_no
      cur_max = channel.messages.maximum(:seq_no) || 0
      self.seq_no = cur_max + 1
    end

    def after_create_cb
      msg = Message.find(id) # Updates the requires_response based on type
      msg.update_columns requires_response: msg.requires_user_response?
      channel.save! # This is required so that the channel's update_send_time is reliably called
    end

    def new_update_seq_no
      seq_no = channel.messages.size
    end

    def check_relative_schedule
      return unless schedule
      field, error = schedule_errors
      return unless field
      errors.add field, error
    end
end
