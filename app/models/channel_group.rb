# == Schema Information
#
# Table name: channel_groups
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  description        :text
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  tparty_keyword     :string(255)
#  keyword            :string(255)
#  default_channel_id :integer
#  moderator_emails   :text
#  real_time_update   :boolean
#  deleted_at         :datetime
#  web_signup         :boolean          default(FALSE)
#

class ChannelGroup < ApplicationRecord
  belongs_to :user
  belongs_to :default_channel, class_name: "Channel"

  has_many :channels, before_add: :check_channel_group_credentials
  has_many :subscriber_responses

  validates :name, presence: true, uniqueness: {
    scope: %i(user_id deleted_at),
  }
  validates :keyword, uniqueness: {
    scope: %i(tparty_keyword deleted_at),
    case_sensitive: false,
    allow_blank: true,
  }
  validates :tparty_keyword, presence: true, tparty_keyword: true
  validates :moderator_emails, allow_blank: true, emails: true

  before_create :add_keyword
  before_destroy :remove_keyword
  after_update :update_channel_tparty_keywords

  acts_as_paranoid

  after_initialize do |channel_group|
    if channel_group.new_record?
      begin
        channel_group.tparty_keyword ||= ENV["TPARTY_PRIMARY_KEYWORD"]
      rescue ActiveModel::MissingAttributeError => e
        raise e.message
      end
    end
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

  def all_channel_subscribers
    channels.includes(:subscribers).map(&:subscribers).flatten
  end

  def process_subscriber_response(subscriber_response)
    case ChannelGroup.identify_command(subscriber_response.content_text)
    when :start
      process_start_command(subscriber_response)
    when :stop
      process_stop_command(subscriber_response)
    when :custom
      process_custom_command(subscriber_response)
    else
      false
    end
  end

  def process_start_command(subscriber_response)
    phone_number = subscriber_response.origin

    return false if !phone_number || phone_number.blank?
    return false unless default_channel
    return true if channels.with_subscriber(phone_number).size > 0

    subscriber = user.subscribers.find_by_phone_number(phone_number)
    unless subscriber
      subscriber = user.subscribers.create!(phone_number: phone_number, name: phone_number)
    end
    default_channel.subscribers.push subscriber
    true
  end

  def process_stop_command(subscriber_response)
    phone_number = subscriber_response.origin
    return false if phone_number.blank?

    found = false
    channels.with_subscriber(phone_number).find_each do |ch|
      found = true
      ch.subscribers.destroy ch.subscribers.find_by_phone_number(phone_number)
    end

    found
  end

  def process_custom_command(subscriber_response)
    return true if process_on_demand_channels(subscriber_response)
    ch = subscriber_response.channel
    ch ? ask_channel_to_process_subscriber_response(ch, subscriber_response) : false
  end

  def process_on_demand_channels(subscriber_response)
    msg = subscriber_response.content_text

    return false if msg.blank?
    tokens = msg.split
    return false unless tokens.length == 1

    channels
      .where(
        "type = :type AND LOWER(one_word) = :one_word_downcase",
        type: "OnDemandMessagesChannel",
        one_word_downcase: tokens[0].downcase,
      )
      .first
      &.process_subscriber_response subscriber_response
  end

  def ask_channel_to_process_subscriber_response(channel, subscriber_response)
    return channel.process_custom_command(subscriber_response)
  end

  def messages_report(options = {})
    col_names = [
      "User Name", "Phone Number", "Channel", "Message", "Sent At",
      "Response", "Received At"
    ]

    CSV.generate(options) do |csv|
      csv << col_names
      subscriber_responses.includes(:subscriber).find_each do |sr|
        record = []
        next if sr.subscriber.blank?
        record << sr.subscriber.name
        record << sr.subscriber.phone_number
        record << "" # channel
        record << "" # message
        record << "" # sent_at
        record << sr.content_text
        record << sr.created_at
        csv << record
      end

      channels.find_each do |ch|
        ch.subscriber_responses.includes(:subscriber, :message).find_each do |sr|
          record = []
          next if sr.subscriber.blank?
          record << sr.subscriber.name
          record << sr.subscriber.phone_number
          record << ch.name
          record << (sr.message.present? ? sr.message.caption : "")
          record << (sr.message.present? ? sr.message.delivery_notices.where(subscriber_id: sr.subscriber.id).first.created_at : "")
          record << sr.content_text
          record << sr.created_at
          csv << record
        end
      end
    end
  end

  private

    def update_channel_tparty_keywords
      channels.each do |channel|
        channel.tparty_keyword = self.tparty_keyword
        channel.save
      end
    end

    def check_channel_group_credentials(channel)
      if channel && channel.class != Hash
        if channels.size > 0 && channel.user_id != channels.first.user_id
          raise ActiveRecord::Rollback, "Channel has to be of same user."
        end

        if channel.channel_group && channel.channel_group != self
          raise ActiveRecord::Rollback, "Channel is already part of another group."
        end
      end
      true
    end

    def add_keyword
      cg = ChannelGroup.find_by_tparty_keyword(tparty_keyword)
      unless cg
        MessagingManagerWorker.perform_async "add_keyword", "keyword" => tparty_keyword
      end
    end

    def remove_keyword
      if tparty_keyword && ChannelGroup.by_tparty_keyword(tparty_keyword).count == 1
        MessagingManagerWorker.perform_async "remove_keyword", "keyword" => tparty_keyword
      end
    end
end
