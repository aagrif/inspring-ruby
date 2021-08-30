module ResponseActionsHelper
  def message_summary(message_id)
    "#{message_id}-#{Message.find(message_id).caption.slice(0, 20)}"
  end
end
