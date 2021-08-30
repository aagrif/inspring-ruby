class MessagingManagerWorker
  include Sidekiq::Worker

  def self.add_keyword(keyword)
    StatsD.increment "messaging_manager_worker.add_keyword"
    MessagingManager.init_instance.add_keyword keyword
  end

  def self.remove_keyword(keyword)
    StatsD.increment "messaging_manager_worker.remove_keyword"
    MessagingManager.init_instance.remove_keyword(keyword)
  end

  def self.broadcast_message(message_id)
    StatsD.increment "messaging_manager_worker.broadcast_message.#{message_id}"
    message = Message.find(message_id)
    return unless message
    channel = message.channel
    return unless channel
    subscribers = channel.subscribers
    return if subscribers.empty?

    MessagingManager.init_instance.broadcast_message message, subscribers
    message.perform_post_send_ops subscribers
  end

  def perform(action, opts = {})
    StatsD.increment "messaging_manager_worker.perform"
    case action
    when "add_keyword"
      self.class.add_keyword opts["keyword"]
    when "remove_keyword"
      self.class.remove_keyword opts["keyword"]
    when "broadcast_message"
      self.class.broadcast_message opts["message_id"]
    end
  end
end
