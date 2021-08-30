class MessageFactoryService
  def initialize(strong_params, params, message: nil, channel: nil)
    @strong_params = strong_params.to_h
    @params = params
    @current_message = message
    @channel = channel

    if @current_message.nil? && message_type != "ActionMessage"
      @strong_params.delete "action_attributes"
    end

    if message_type == "ActionMessage"
      @data = { resume_from_last_state: @strong_params["action_attributes"]["resume_from_last_state"] }
      @strong_params["action_attributes"].delete "resume_from_last_state"
    end
  end

  def message
    @message ||= begin
      message = if @current_message.nil?
        @channel.messages.new @strong_params
      else
        @current_message.assign_attributes @strong_params
        @current_message.action = nil unless message_type == "ActionMessage"
        @current_message
      end

      if switch_channel_action_message?
        message.action.data[:to_channel_in_group] = @params[:to_channel_in_group]
        message.action.data[:to_channel_out_group] = @params[:to_channel_out_group]
        message.action.data[:resume_from_last_state] = @data[:resume_from_last_state]
      end

      if @params[:one_time_or_recurring].present?
        case @params[:one_time_or_recurring]
        when "one_time"
          message.recurring_schedule = nil
        when "recurring"
          message.next_send_time = nil
          message.update_next_send_time_for_recurring_schedule
        end
      end

      message
    end
  end

  private

    def message_type
      @strong_params["type"]
    end

    def message_action
      @strong_params.try(:[], "action_attributes").try(:[], "type")
    end

    def switch_channel_action_message?
      message_type == "ActionMessage" && message_action == "SwitchChannelAction"
    end
end
