# == Schema Information
#
# Table name: channels
#
#  id                       :integer          not null, primary key
#  name                     :string(255)
#  description              :text
#  user_id                  :integer
#  type                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  keyword                  :string(255)
#  tparty_keyword           :string(255)
#  next_send_time           :datetime
#  schedule                 :text
#  channel_group_id         :integer
#  one_word                 :string(255)
#  suffix                   :string(255)
#  moderator_emails         :text
#  real_time_update         :boolean
#  deleted_at               :datetime
#  relative_schedule        :boolean
#  send_only_once           :boolean          default(FALSE)
#  active                   :boolean          default(TRUE)
#  allow_mo_subscription    :boolean          default(TRUE)
#  mo_subscription_deadline :datetime
#

class Channel < ApplicationRecord
  include ActionView::Helpers
  include IceCube

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :not_too_old, -> { where("next_send_time >= ?", 8.hours.ago) }
  scope :pending_send, -> { not_too_old.where("next_send_time <= ?", Time.current) }

  belongs_to :user
  belongs_to :channel_group

  has_many :messages, dependent: :destroy
  has_many :subscriptions
  has_many :subscribers,
           through: :subscriptions,
           before_add: :check_subscriber_uniqueness,
           after_add: :after_subscriber_add_callback,
           before_remove: :before_subscriber_remove_callback
  has_many :subscriber_responses

  validates :name, presence: true, uniqueness: {
    scope: %i(user_id deleted_at),
  }
  validates :type, presence: true, inclusion: {
    in: %w(
      AnnouncementsChannel ScheduledMessagesChannel OrderedMessagesChannel
      OnDemandMessagesChannel RandomMessagesChannel
      IndividuallyScheduledMessagesChannel SecondaryMessagesChannel
    ),
  }
  validates :keyword, uniqueness: {
    scope: %i(tparty_keyword deleted_at),
    case_sensitive: false,
    allow_blank: true,
  }
  validates :tparty_keyword, presence: true, tparty_keyword: true
  validates :one_word, allow_blank: true, one_word: true, uniqueness: {
    scope: %i(channel_group_id deleted_at),
  }
  validates :moderator_emails, allow_blank: true, emails: true

  before_create :add_keyword
  before_save :update_next_send_time
  before_destroy :remove_keyword

  serialize :schedule, Hash

  acts_as_paranoid

  after_initialize do |channel|
    if channel.new_record?
      begin
        channel.type ||= "AnnouncementsChannel"
        channel.tparty_keyword ||= if channel.channel_group
          channel.channel_group.tparty_keyword
        else
          ENV["TPARTY_PRIMARY_KEYWORD"]
        end
        channel.relative_schedule ||= false
      rescue ActiveModel::MissingAttributeError => e
        raise e.message
      end
    end
  end

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Channel.model_name
      end
    end

    super
  end

  def self.child_classes
    self.validators.select {
      |v| v.attributes == [:type] && v.kind_of?(ActiveModel::Validations::InclusionValidator)
    }.first.options[:in].map(&:constantize)
  end

  def self.find_by_keyword(keyword)
    where("LOWER(keyword) = ?", keyword.downcase).first
  end

  def self.by_keyword(keyword)
    where("LOWER(keyword) = ?", keyword.downcase)
  end

  def self.find_by_tparty_keyword(tparty_keyword)
    where("LOWER(tparty_keyword) = ?", tparty_keyword.downcase).first
  end

  def self.by_tparty_keyword(tparty_keyword)
    where("LOWER(tparty_keyword) = ?", tparty_keyword.downcase)
  end

  def self.with_subscriber(phone_number)
    phone_number = Subscriber.format_phone_number(phone_number)
    includes(:subscribers).where(subscribers: { phone_number: phone_number, deleted_at: nil })
  end

  def self.get_next_seq_no(seq_no, seq_nos)
    return nil if seq_nos.nil? || seq_nos.count < 1
    return seq_nos[0] if seq_no.nil? || seq_no == 0

    matched = false
    seq_nos.each do |curr_no|
      return curr_no if matched
      return curr_no if curr_no > seq_no
      matched = true if curr_no == seq_no
    end

    nil
  end

  def self.identify_command(message_text)
    return :custom if message_text.blank?

    tokens = message_text.split
    return :custom if tokens.length > 1
    return nil if tokens.length < 1

    case tokens[0]
    when /start/i then :start
    when /stop/i then :stop
    else :custom
    end
  end

  def send_scheduled_messages
    StatsD.increment "channel.#{self.id}.send_scheduled_messages"
    Rails.logger.info "START Channel:#{self.id} SendScheduledMessages"

    msg_no_subs_hash = group_subscribers_by_message

    if msg_no_subs_hash.present?
      msg_no_subs_hash.each do |msg_no, subscribers|
        message = Message.where(id: msg_no).try(:first)
        next if message.nil?
        if message.internal?
          Rails.logger.info "INFO: MessageId:#{message.id} Internal, send to subscribers called"
          message.send_to_subscribers subscribers
        else
          if subscribers.nil? || subscribers.count == 0
            Rails.logger.info "ScheduledMessages: No subscribers for MessageId#{msg_no}"
          else
            Rails.logger.info "INFO SendingMessageID: #{message.id} to #{subscribers.count} subscribers"
            MessagingManager.init_instance.broadcast_message message, subscribers
          end
        end
      end

      perform_post_send_ops msg_no_subs_hash

      msg_no_subs_hash.each do |msg_no, subs|
        message = Message.find_by(id: msg_no)
        message.perform_post_send_ops subs if message
      end
    end

    reset_next_send_time
  end

  def group_subscribers_by_message; end

  def perform_post_send_ops(msg_no_subs_hash); end

  def converted_schedule
    sch = self[:schedule]
    if sch.present?
      the_schedule = Schedule.new(Time.current)
      the_schedule.add_recurrence_rule RecurringSelect.dirty_hash_to_rule(sch)
      the_schedule
    end
  end

  def schedule=(new_rule)
    self[:schedule] = if new_rule != "{}" &&
                        new_rule != "null" &&
                        RecurringSelect.is_valid_rule?(new_rule)
      RecurringSelect.dirty_hash_to_rule(new_rule).to_hash
    end
  end

  def reset_next_send_time
    sch = converted_schedule
    if sch.to_s == "Daily"
      self.next_send_time = (Time.current + 1.day).change(hour: rand(9..17), min: rand(0..59))
    else
      self.next_send_time = sch.next_occurrence(Time.current) if sch
    end

    self.save!
  end

  def get_all_seq_nos
    messages.select(:seq_no).order(:seq_no).distinct.map(&:seq_no)
  end

  # Defines whether scheduling is relevant for this channel type.
  def has_schedule?
    raise NotImplementedError
  end

  # Defines whether the move-up and move-down actions make any sense.
  def sequenced?
    raise NotImplementedError
  end

  def broadcastable?
    raise NotImplementedError
  end

  # Give a two character short form for the channel type.
  def type_abbr
    raise NotImplementedError
  end

  def individual_messages_have_schedule?
    raise NotImplementedError
  end

  def sent_messages_ids(subscriber)
    DeliveryNotice
      .where(
        subscriber_id: [subscriber.id],
        message_id: messages.select(:id).map(&:id),
      )
      .select(:message_id)
      .map(&:message_id)
  end

  def pending_messages_ids(subscriber)
    messages.where.not(id: sent_messages_ids(subscriber)).select(:id).map(&:id)
  end

  def process_subscriber_response(subscriber_response)
    case Channel.identify_command(subscriber_response.content_text)
    when :start
      process_start_command subscriber_response
    when :stop
      process_stop_command subscriber_response
    when :custom
      process_custom_command subscriber_response
    else
      false
    end
  end

  def process_start_command(subscriber_response)
    StatsD.increment "channel.command.start"
    Rails.logger.info "Starting subscription to a new channel"
    unless allow_mo_subscription
      StatsD.increment "channel.command.rejected.not_allowing_mo"
      Rails.logger.error "Mobile Originated Subscription not allowed #{subscriber_response.inspect}."
      return false
    end

    if mo_subscription_deadline.present? && Time.current > mo_subscription_deadline
      StatsD.increment "channel.command.rejected.mo_expired"
      Rails.logger.error "Mobile Originated Subscription expired at #{mo_subscription_deadline} #{subscriber_response.inspect}."
      return false
    end

    phone_number = subscriber_response.origin
    unless phone_number
      StatsD.increment "channel.command.rejected.no_phone_number"
      return false
    end

    subscriber = user.subscribers.find_by_phone_number(phone_number)
    unless subscriber
      Rails.logger.info "Creating new subscriber with phone number #{phone_number}"
      StatsD.increment "channel.command.create_subscriber"
      subscriber = user.subscribers.create!(phone_number: phone_number, name: phone_number)
    end

    unless subscribers.include? subscriber
      self.subscribers.push subscriber
      notice_text = "Added subscriber to " \
                    "<a href='/channels/#{self.id}'>#{name}</a>"
      ActionNotice.create caption: notice_text, subscriber: subscriber
      save
    end
    true
  end

  def process_stop_command(subscriber_response)
    phone_number = subscriber_response.origin
    return false if phone_number.blank?

    subscriber = subscribers.find_by_phone_number(phone_number)
    return false unless subscriber

    subscribers.destroy subscriber
    save!
    true
  end

  def process_custom_command(subscriber_response)
    return true if process_custom_channel_command(subscriber_response)
    message = subscriber_response.message
    message ? message.process_subscriber_response(subscriber_response) : false
  end

  def process_custom_channel_command(_subscriber_response)
    false
  end

  def messages_report(options = {})
    col_names = ["User Name", "Phone Number", "Message", "Sent At", "Response", "Received At"]
    CSV.generate(options) do |csv|
      csv << col_names
      subscriber_responses.includes(:subscriber, :message).find_each do |sr|
        record = []
        next if sr.subscriber.blank?
        record << sr.subscriber.name
        record << sr.subscriber.phone_number
        record << (sr.message.present? ? sr.message.caption : "")
        record << (sr.message.present? ? sr.message.delivery_notices.where(subscriber_id: sr.subscriber.id).first.created_at : "")
        record << sr.content_text
        record << sr.created_at
        csv << record
      end
    end
  end

  def in_channel_group?
    !channel_group_id.blank?
  end

  def sibling_channel_ids
    if in_channel_group?
      channel_group_channel_ids = self.channel_group.channels.map(&:id)
      channel_group_channel_ids&.delete(self.id)
      Array(channel_group_channel_ids)
    else
      []
    end
  end

  private

    def add_keyword
      unless Channel.find_by_tparty_keyword(tparty_keyword)
        MessagingManagerWorker.perform_async "add_keyword", "keyword" => tparty_keyword
      end
    end

    def remove_keyword
      if Channel.by_tparty_keyword(tparty_keyword).count == 1
        MessagingManagerWorker.perform_async "remove_keyword", "keyword" => tparty_keyword
      end
    end

    def update_next_send_time
      sch = converted_schedule
      if sch.to_s == "Daily"
        self.next_send_time = (Time.current + 1.day).change(hour: rand(9..17), min: rand(0..59))
      else
        self.next_send_time = sch.next_occurrence(Time.current) if sch
      end

      begin
        self.next_send_time = 1.minute.ago if individual_messages_have_schedule?
      rescue NotImplementedError
      end

      true
    end

    def check_subscriber_uniqueness(subscriber)
      if channel_group
        siblings = channel_group.channels.includes(:subscribers)
        siblings.find_each do |ch|
          conflict_subscriber = ch.subscribers.find { |subs| subs.phone_number == subscriber.phone_number }
          if conflict_subscriber
            ch.subscribers.delete(conflict_subscriber)
            notice_text = "Removed subscriber to "\
              "<a href=\"/channels/#{self.id}\">#{name}</a> " \
              "because of a pending new request."
            ActionNotice.create caption: notice_text, subscriber: conflict_subscriber
          end
        end
      end
    end

    def after_subscriber_add_callback(subscriber); end
    
    def before_subscriber_remove_callback(subscriber); end
end
