# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#  data            :text
#

class SendMessageAction < Action
  include Rails.application.routes.url_helpers
  include ActionView::Helpers

  validates :message_to_send, presence: true

  before_validation :construct_action
  validate :check_action_text

  def type_abbr
    "Send message"
  end

  def description
    "Send a message to the subscriber"
  end

  def check_action_text
    unless as_text =~ /^Send message \d+$/
      errors.add :as_text, "action format is invalid"
    end
  end

  def construct_action
    self.as_text = "Send message #{message_to_send}"
  end

  def execute(options = {})
    subscribers = options[:subscribers]
    return false if subscribers.nil? || subscribers.empty?

    message = Message.find(message_to_send)
    MessagingManager.init_instance.broadcast_message message, subscribers, check_duplicate: false
    message.perform_post_send_ops subscribers
    true
  rescue ActiveRecord::RecordNotFound
    false
  end
end
