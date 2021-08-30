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

class IndividuallyScheduledMessagesChannel < Channel
  include IceCube

  def self.system_channel?
    false
  end

  def has_schedule?
    false
  end

  #Defines whether the move-up and move-down actions make any sense.
  def sequenced?
    false
  end

  def broadcastable?
    false
  end

  def type_abbr
    "Ind. Scheduled"
  end

  def individual_messages_have_schedule?
    true
  end

  def send_scheduled_messages
    if relative_schedule
      send_relatively_scheduled_messages
    else
      send_absolutely_scheduled_messages
    end
  end

  private

    # Assumes the channel has relatively scheduled messages.
    def send_relatively_scheduled_messages
      messages.pending_send.find_each do |message|
        subscriber_ids = message.options[:subscriber_ids]
        next if subscriber_ids.blank?
        current_time = Time.current
        valid_subscribers = subscriptions.where(subscriber_id: subscriber_ids)
          .select { |subscription| message.target_time(subscription.created_at) <= current_time }
          .map(&:subscriber)

        if valid_subscribers.size > 0
          send_message message, valid_subscribers
          
          subscriber_ids -= valid_subscribers.map(&:id)
          message.options[:subscriber_ids] = subscriber_ids
          message.next_send_time = if subscriber_ids.size > 0
            message.target_time(subscriptions.find_by(subscriber_id: subscriber_ids[0]).created_at)
          end

          message.save
        end
      end
    end

    # Assumes the channel has absolutely scheduled messages.
    def send_absolutely_scheduled_messages
      messages.pending_send.find_each do |message|
        # subscribers = subscriptions.where("created_at <= ?", message.next_send_time).map(&:subscriber)
        subscribers = subscriptions.map(&:subscriber)
        send_message message, subscribers if subscribers.size > 0

        if message.recurring_schedule.present?
          message.update_next_send_time_for_recurring_schedule
          message.save!
        end
      end
    end

    def send_message(message, subscribers)
      if message.internal?
        Rails.logger.info "INFO: MessageId:#{message.id} Internal, send to subscribers called"
        message.send_to_subscribers subscribers
      else
        Rails.logger.info "INFO SendingMessageID: #{message.id} to #{subscribers.size} subscribers"
        MessagingManager.init_instance.broadcast_message message, subscribers
      end
    end

    def after_subscriber_add_callback(subscriber)
      return unless relative_schedule

      if subscriber.data[:resume_from_last_state]
        last_subscription = Subscription.deleted.where(channel: self, subscriber: subscriber)
          .order(deleted_at: :desc).first

        if last_subscription.present?
          subscription = Subscription.find_by(subscriber: subscriber, channel: self)
          if subscription
            subscription.created_at = last_subscription.created_at
            subscription.save!
          end

          last_delivered_msg_tt = DeliveryNotice.where(subscriber: subscriber, channel: self)
            .where("created_at > ?", last_subscription.created_at)
            .order(created_at: :desc)
            .first&.message&.target_time(last_subscription.created_at)

          messages.active.find_each do |message|
            msg_target_time = message.target_time(last_subscription.created_at)
            next if last_delivered_msg_tt.present? && last_delivered_msg_tt >= msg_target_time
            subscriber_ids = message.options[:subscriber_ids] || []
            if subscriber_ids.blank?
              subscription = subscriptions.find_by(subscriber: subscriber)
              message.next_send_time = msg_target_time
            end
            message.options[:subscriber_ids] = subscriber_ids + [subscriber.id]
            message.save
          end
        end
        subscriber.data[:resume_from_last_state] = nil
        subscriber.save
      else
        messages.active.find_each do |message|
          subscriber_ids = message.options[:subscriber_ids] || []
          if subscriber_ids.blank?
            subscription = subscriptions.find_by(subscriber: subscriber)
            message.next_send_time = message.target_time(subscription.created_at)
          end
          message.options[:subscriber_ids] = subscriber_ids + [subscriber.id]
          message.save
        end
      end
    end

    def before_subscriber_remove_callback(subscriber)
      messages.active.find_each do |message|
        next if message.options[:subscriber_ids].blank?
        message.options[:subscriber_ids] -= [subscriber.id]
        message.save
      end
    end
end
