module MessagesHelper
  def message_types
    Message.child_classes
  end

  def user_message_types
    Message.child_classes.select { |c| c.user_accessible_message_type? }.map { |c| c.to_s.to_sym }
  end

  def base_message_length(message)
    bml = ENV["TPARTY_SUFFIX_LENGTH"].to_i
    bml += message.channel.suffix.length if message.channel && message.channel.suffix
    bml
  end

  def total_message_length(message)
    tml = base_message_length(message)
    tml += message.caption.length if message.caption
    tml
  end
end
