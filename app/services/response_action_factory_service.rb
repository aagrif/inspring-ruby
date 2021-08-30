class ResponseActionFactoryService
  def initialize(strong_params, params, response_action: nil, message: nil)
    @strong_params = strong_params.to_h
    @params = params
    @current_response_action = response_action
    @message = message
    @data = { resume_from_last_state: @strong_params["action_attributes"]["resume_from_last_state"] }
    @strong_params["action_attributes"].delete "resume_from_last_state"
  end

  def response_action
    @response_action ||= begin
      response_action = if @current_response_action.nil?
        @message.response_actions.new @strong_params
      else
        @current_response_action.assign_attributes @strong_params
        @current_response_action
      end

      if switch_channel_action?
        response_action.action.data[:to_channel_in_group] = @params[:to_channel_in_group]
        response_action.action.data[:to_channel_out_group] = @params[:to_channel_out_group]
        response_action.action.data[:resume_from_last_state] = @data[:resume_from_last_state]
      end

      response_action
    end
  end

  private

    def action_type
      @strong_params.try(:[], "action_attributes").try(:[], "type")
    end

    def switch_channel_action?
      action_type == "SwitchChannelAction"
    end
end
