class TwilioController < ApplicationController
  def callback
    Rails.logger.info "Twilio_Callback: #{params.inspect}"
    response = handle_request(params)
    if response
      StatsD.increment("twilio.callback.ok")
      render plain: response, status: :ok
    else
      StatsD.increment("twilio.callback.error")
      Rails.logger.error "Twilio controller could not handle: #{params}"
      render plain: "Error request", status: :internal_server_error
    end
  end

  private

    def handle_request(params)
      raise "no data in request" if params["Body"].blank? || params["From"].blank?
      message_manager = IncomingMessageManager.new(params)
      message_manager.process
      "OK"
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      false
    end
end
