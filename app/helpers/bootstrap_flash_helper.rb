module BootstrapFlashHelper
  ALERT_TYPES = %i(success info warning danger) unless const_defined?(:ALERT_TYPES)

  def bootstrap_flash(options = {})
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = case type.to_sym
      when :notice then :success
      when :alert, :error then :danger
      end

      next unless ALERT_TYPES.include?(type)

      tag_class = options.extract!(:class)[:class]
      tag_options = {
        class: "alert alert-#{type} #{tag_class}",
        role: "alert",
      }.merge(options)

      close_button = content_tag(
        :button,
        raw('<span aria-hidden="true">&times;</span>'),
        :type => "button",
        :class => "close",
        "data-dismiss" => "alert",
        "aria-label" => "Close",
      )

      Array(message).each do |msg|
        text = content_tag(:div, close_button + msg, tag_options)
        flash_messages << text if msg
      end
    end

    flash_messages.join("\n").html_safe
  end
end
