class TpartyScheduledMessageSender
  include Sidekiq::Worker

  def perform
    StatsD.increment "tparty_scheduled_messages_sender.perform"
    self.class.send_scheduled_messages
  end

  def self.send_scheduled_messages
    channels_pending_send.each do |channel|
      channel.send_scheduled_messages
    end
  end

  def self.channels_pending_send
    Channel.pending_send
      .or(Channel.where(type: %w(IndividuallyScheduledMessagesChannel)))
      .active
  end
end
