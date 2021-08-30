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

class ScheduledMessagesChannel < Channel
  SENT_MESSAGE_MARKER = 1_000_000

  def self.system_channel?
    false
  end

  def has_schedule?
    true
  end

  # Defines whether the move-up and move-down actions make any sense.
  def sequenced?
    true
  end

  def broadcastable?
    false
  end

  def type_abbr
    "Scheduled"
  end

  def individual_messages_have_schedule?
    false
  end

  def group_subscribers_by_message
    message = messages.where("seq_no < ?", SENT_MESSAGE_MARKER).order(:seq_no).first
    { message.id => subscribers.to_a } if message
  end

  def perform_post_send_ops(msg_no_subs_hash)
    return unless msg_no_subs_hash&.first

    message_id, subscribers = msg_no_subs_hash.first
    message = Message.find(message_id)
    return unless message

    last_sent_message = messages.where("seq_no > ?", SENT_MESSAGE_MARKER)
      .order(seq_no: :desc).first
    if last_sent_message
      message.update_columns seq_no: last_sent_message.seq_no + 1
    else
      message.update_columns seq_no: SENT_MESSAGE_MARKER + 1
    end
  end
end
