class MessagingManager
  def self.init_instance
    mmclass.new
  end

  def self.mmclass
    case ENV["TPARTY_MESSAGING_SYSTEM"]
    when "Twilio" then TwilioMessagingManager
    else TwilioMessagingManager
    end
  end

  def self.get_final_message_content(message, subscriber)
    message_text = if message.is_a?(TagMessage)
      message.caption_for(subscriber)
    else
      message.caption.dup
    end

    if message.channel && message.channel.suffix.present?
      message_text << " #{message.channel.suffix}"
    end
    message_text
  end

  def self.duplicate_message?(channel_id, subscriber_id, message_text)
    return false if channel_id.nil?
    subscription = Channel.find(channel_id).subscriptions.find_by(subscriber_id: subscriber_id)
    last_message_texts = DeliveryNotice.where(channel_id: channel_id, subscriber_id: subscriber_id)
      .where("created_at >= ?", [subscription&.created_at, 3.hours.ago].max)
      .order(created_at: :desc).pluck(:caption)
    last_message_texts.include? message_text
  end

  def broadcast_message(message, subscribers, check_duplicate: true)
    subscribers = subscribers.reject { |s| s.nil? }
    phone_numbers = subscribers.map(&:phone_number)
    content_url = message.content.exists? ? message.content.url : nil

    from_num = if message.options && message.options[:tparty_keyword].present?
      message.options[:tparty_keyword]
    elsif message.channel && message.channel.tparty_keyword.present?
      message.channel.tparty_keyword
    end

    subscribers.each do |subscriber|
      if message.is_a?(TagMessage) && !message.message_text?(subscriber)
        Rails.logger.info "Skipping Subscriber #{subscriber.id} for message " \
                          "#{message.id} due to no matching key."
        subscriber.mark_as_last_message(message.channel, message)
        subscriber.save
        next
      end

      title_text = get_final_message_title(message, subscriber)
      message_text = MessagingManager.get_final_message_content(message, subscriber)

      tparty_identifier = message.tparty_identifier
      channel_id = message.channel_id
      channel_group_id = message.channel&.channel_group&.id

      if check_duplicate && MessagingManager.duplicate_message?(channel_id, subscriber.id, message_text)
        Rails.logger.info %(Duplicate message "#{message_text}" detected for #{subscriber.name} and sending prevented.)
        next
      end

      if send_message(
          subscriber.phone_number,
          title_text,
          message_text,
          content_url,
          from_num,
        )
        dn = if message.primary?
          DeliveryNotice.create(
            message: message,
            title: title_text,
            caption: message_text,
            subscriber: subscriber,
            options: message.options,
            tparty_identifier: tparty_identifier,
            channel_id: channel_id,
            channel_group_id: channel_group_id,
          )
        else
          DeliveryNotice.create(
            message: Message.find(message.options[:message_id]),
            subscriber: subscriber,
            options: message.options,
            tparty_identifier: tparty_identifier,
            channel_id: channel_id,
            channel_group_id: channel_group_id,
          )
        end
        subscriber.mark_as_last_message(message.channel, message)

        Rails.logger.info "DeliveryNotice: #{dn.nil? ? 'nil' : dn.id} for "\
                          "Message: #{message.id} Subscriber: #{subscriber.id}"
      else
        Rails.logger.error "Broadcast message #{message.caption} failed."
      end
    end
  end

  def get_final_message_title(message, _subscriber)
    message.title
  end

  # Overridable methods

  def send_message(phone_number, title, message_text, content_url, from_num); end

  def validate_tparty_keyword(value); end

  def add_keyword(keyword); end

  def remove_keyword(keyword); end

  # Whether the external service uses message itself to differentiate
  # target of MO messages.
  def keyword_based_service?; end

  private

    def self.substitute_placeholders(content, placeholders)
      attr_value_pairs = {}

      if placeholders
        placeholders.split(";").each do |str|
          md = str.match(/(.+)=(.+)/)
          attr_value_pairs[md[1].upcase] = md[2] if md
        end
      end

      attr_value_pairs.each do |attr, value|
        content.gsub!(/\%\%#{attr}\%\%/i, value)
      end

      content.gsub(/\%\%.+\%\%/, "")
    end
end
