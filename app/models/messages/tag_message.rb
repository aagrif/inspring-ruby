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

class TagMessage < Message
  def self.user_accessible_message_type?
    true
  end

  def type_abbr
    "Tag"
  end

  def caption_for(subscriber)
    return false if !(subscriber.has_custom_attributes? && message_text?(subscriber))

    keys = matching_message_options(subscriber)
    candidate_msgs = message_options.select { |mo| keys.include?(mo[:key]) }.map(&:value)
    sent_msgs = DeliveryNotice
      .where(
        subscriber_id: subscriber.id,
        caption: candidate_msgs,
      )
      .map(&:caption)
    remaining_msgs = candidate_msgs - sent_msgs

    remaining_msgs.length > 0 ? remaining_msgs.sample : candidate_msgs.sample
  end

  def message_text?(subscriber)
    matching_message_options(subscriber).length > 0
  end

  def matching_message_options(subscriber)
    common_keys = []
    subscriber.custom_attributes.keys.each do |sk|
      common_keys.push message_option_keys.select { |mk| mk.downcase == sk.downcase }
    end
    common_keys
  end

  def message_option_keys
    @message_option_keys ||= message_options.all.map(&:key)
  end
end
