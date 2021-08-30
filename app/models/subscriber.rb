# == Schema Information
#
# Table name: subscribers
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  phone_number          :string(255)
#  remarks               :text
#  last_msg_seq_no       :integer
#  user_id               :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  email                 :string(255)
#  deleted_at            :datetime
#  additional_attributes :text
#  data                  :text
#

require_relative "./mixins/json_serialized_field"

class Subscriber < ApplicationRecord
  include JSONSerializedField

  belongs_to :user

  has_many :subscriptions
  has_many :channels, through: :subscriptions
  has_many :delivery_notices
  has_many :subscriber_responses

  validates :phone_number, presence: true, phone_number: true, uniqueness: {
    scope: %i(user_id deleted_at),
  }
  validates :email, format: { with: /\A.+@.+\z/ }, allow_blank: true

  json_serialize :data

  before_validation :normalize_phone_number

  acts_as_paranoid

  def self.find_by_phone_number(phone_number)
    ref_phone_number = Subscriber.format_phone_number(phone_number)
    where(phone_number: ref_phone_number).first
  end

  def custom_attributes
    @supplied_attributes ||= begin
      attribs = {}
      additional_attributes.to_s.split(";").each do |item|
        key, value = item.to_s.split("=", 2)
        key.downcase!
        attribs[key] = value
      end
      attribs
    end
  end

  def has_custom_attributes?
    custom_attributes && custom_attributes.is_a?(Hash) && custom_attributes.keys.size > 0
  end

  def mark_as_last_message(channel, message)
    data["channels"] = {} if data["channels"].blank?
    data["channels"][channel.id] = {} if data["channels"][channel.id].blank?
    data["channels"][channel.id]["last_sent"] = Time.current
    data["channels"][channel.id]["message_id"] = message.id
  end

  private

    def self.format_phone_number(phone_number)
      return "" if phone_number.blank?

      digits = phone_number.gsub(/\D/, "").split(//)
      case digits.length
      when 10 then "+1#{digits.join}"
      when 11 then "+#{digits.join}"
      end
    end

    def normalize_phone_number
      self.phone_number = Subscriber.format_phone_number(phone_number)
    end
end
