class TwilioMessagingManager < MessagingManager
  attr_accessor :twrapper

  def self.keyword_based_service?
    false
  end

  def initialize(wrapper = nil)
    @twrapper = wrapper || TwilioWrapper.new
  end

  def send_message(phone_number, title, message_text, content_url, from_num)
    if from_num.nil?
      Rails.logger.error "TwillioNumber is not configured. Broadcast_message failed"
      false
    else
      twrapper.send_message(phone_number, title, message_text, content_url, from_num)
    end
  end

  def validate_tparty_keyword(_value)
    nil
  end

  def add_keyword(_keyword)
    true
  end

  def remove_keyword(_keyword)
    true
  end
end
