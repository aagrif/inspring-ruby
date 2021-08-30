module SubscriberActivitiesHelper
  def sa_title(target, criteria, type, unprocessed)
    content = case type
    when "SubscriberResponse" then "Subscriber responses "
    when "DeliveryNotice" then "Delivery notices "
    else "Subscriber activities "
    end

    content << "(unprocessed)" if unprocessed

    content << case criteria
    when "Subscriber" then " of #{target.name}"
    when "Channel" then " of #{target.name}"
    when "ChannelGroup" then " of #{target.name}"
    when "Message" then " for '#{target.caption[0..30]}'"
    end
  end

  def sa_description(sa)
    case sa.type
    when "DeliveryNotice"
      content = "We sent "
      content << if sa.respond_to?(:options) && sa.options && sa.options[:reminder_message]
                   "reminder message"
                 elsif sa.options && sa.options[:repeat_reminder_message]
                   "repeat reminder message"
                 elsif sa.message.present? && sa.message.caption.present?
                   link_to "'#{sa.message.caption[0, 30]}'",
                           channel_message_path(sa.message.channel, sa.message)
                 end.to_s
      content << " to "
      if sa.subscriber.present?
        content << link_to(sa.subscriber.name, subscriber_path(sa.subscriber))
      end
    when "SubscriberResponse"
      content = if sa.subscriber
        link_to sa.subscriber.name, subscriber_path(sa.subscriber) if sa.subscriber.present?
      else
        sa.origin
      end
      content << " sent '#{sa.caption}'"
    when "ActionNotice"
      content = sa.caption
    end

    (content || "").html_safe
  end

  def sa_delivery_notice_message_fields(sa)
    if sa.options[:reminder_message]
      content = "<dt><strong>Type:</strong></dt><dd>Reminder message<dd>"
      if sa.message
        content << "<dt><strong>Original Message:</strong></dt><dd>"
        content << link_to(
          print_or_dashes(sa.message.caption[0..80]),
          channel_message_path(sa.message.channel, sa.message),
        )
        content << "</dd>"
      end
    elsif sa.options[:repeat_reminder_message]
      content = "<dt><strong>Type:</strong></dt><dd>Repeat reminder message<dd>"
      if sa.message
        content << "<dt><strong>Original Message:</strong></dt><dd>"
        content << link_to(
          print_or_dashes(sa.message.caption[0..80]),
          channel_message_path(sa.message.channel, sa.message),
        )
        content << "</dd>"
      end
    elsif sa.message
      content = "<dt><strong>Message:</strong></dt><dd>"
      content << link_to(
        print_or_dashes(sa.message.caption[0..80]),
        channel_message_path(sa.message.channel, sa.message),
      )
      content << "</dd>"
    end

    (content || "").html_safe
  end

  def sa_path(sa)
    case sa.parent_type
    when :message
      {
        controller: "subscriber_activities",
        message_id: sa.message.id,
        channel_id: sa.channel.id,
        id: sa.id,
      }
    when :subscriber
      {
        controller: "subscriber_activities",
        subscriber_id: sa.subscriber.id,
        id: sa.id,
      }
    when :channel
      {
        controller: "subscriber_activities",
        channel_id: sa.channel.id,
        id: sa.id,
      }
    when :channel_group
      {
        controller: "subscriber_activities",
        channel_group_id: sa.channel_group.id,
        id: sa.id,
      }
    end
  end
end
