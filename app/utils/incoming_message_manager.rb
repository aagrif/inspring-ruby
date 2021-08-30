class IncomingMessageManager
  attr_reader :from_phone, :to_phone, :response_text

  def initialize(params)
    @from_phone = Subscriber.format_phone_number(params["From"])
    @to_phone = Subscriber.format_phone_number(params["To"])
    @response_text = params["Body"].downcase
  end

  # Does smart response text analysis.
  def process
    caption = response_text
    channel = channel_by_keyword
    channel_group = channel_group_by_keyword

    if channel || channel_group
      tmp = response_text.split
      tmp.shift
      caption = tmp.join(" ")
    end

    delivery_notice = nil
    dn_responding_message_unconfigured = nil
    responding_messages_delivery = responding_messages_delivery_with_no_responses(channel, channel_group)

    responding_messages_delivery.each do |dn|
      unless dn.message.check_subscriber_response(response_text)
        dn_responding_message_unconfigured = dn
        next
      end
      delivery_notice = dn
      break
    end

    delivery_notice ||= dn_responding_message_unconfigured
    delivery_notice ||= last_sent_relevant_delivery(channel, channel_group)

    process_delivery_notice(
      delivery_notice,
      caption: caption,
      channel: channel,
      channel_group: channel_group,
    )
  end

  private

    # Processes DeliveryNotice object to create SubscriberResponse object.
    def process_delivery_notice(delivery_notice,
                                caption: response_text,
                                channel: nil,
                                channel_group: nil)
      target ||= channel || channel_group

      if target
        subscriber_response = SubscriberResponse.create(
          caption: caption,
          origin: from_phone,
          tparty_identifier: to_phone,
        )

        if delivery_notice
          delivery_notice.message.subscriber_responses << subscriber_response
          target = delivery_notice.channel || delivery_notice.channel_group
        end

        target.subscriber_responses << subscriber_response
        subscriber = target.user.subscribers&.find_by_phone_number(from_phone)
        subscriber.subscriber_responses << subscriber_response if subscriber

        Rails.logger.info "SubscriberResponseID: #{subscriber_response.id}"
        subscriber_response.try_processing
      end
    end

    # Gets Channel object by channel keyword.
    def channel_by_keyword
      text_components = response_text.split
      if text_components.size > 1
        Channel.by_tparty_keyword(to_phone).by_keyword(text_components[0]).first
      end
    end

    # Gets ChannelGroup object by channel group keyword.
    def channel_group_by_keyword
      text_components = response_text.split
      if text_components.size > 1
        ChannelGroup.by_tparty_keyword(to_phone).by_keyword(text_components[0]).first
      end
    end

    # Gets DeliveryNotice objects for responding message types that need to be replied yet.
    def responding_messages_delivery_with_no_responses(channel = nil, channel_group = nil)
      delivery_notices = DeliveryNotice.includes(:message)
      delivery_notices = delivery_notices.where(channel: channel) if channel
      delivery_notices = delivery_notices.where(channel_group: channel_group) if channel_group
      delivery_notices.where(subscriber_id: potential_subscriber_ids)
        .where(tparty_identifier: to_phone)
        .where("messages.type" => Message.responding_message_types)
        .order(:created_at)
        .select { |dn|
          last_sr = dn.message.subscriber_responses.order(:created_at).last
          last_sr.nil? || last_sr.created_at < dn.created_at
        }
    end

    # Gets the most recent DeliveryNotice object for non-responding message type.
    def last_sent_relevant_delivery(channel = nil, channel_group = nil)
      delivery_notices = DeliveryNotice.includes(:message)
      delivery_notices = delivery_notices.where(channel: channel) if channel
      delivery_notices = delivery_notices.where(channel_group: channel_group) if channel_group
      delivery_notices.where(subscriber_id: potential_subscriber_ids)
        .where(tparty_identifier: to_phone)
        .where.not("messages.type" => Message.responding_message_types)
        .order(created_at: :desc)
        .find { |dn|
          last_sr = dn.message.subscriber_responses.order(:created_at).last
          last_sr.nil? || last_sr.created_at < dn.created_at
        }
    end

    # Gets potential subscriber Ids that are associated with this Twilio #.
    def potential_subscriber_ids
      Subscriber.where(phone_number: from_phone).order(updated_at: :desc).map(&:id)
    end
end
