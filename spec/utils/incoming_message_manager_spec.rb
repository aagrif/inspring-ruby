require 'rails_helper'

describe IncomingMessageManager do

  describe "[parsing]" do
    it 'parses a message from Twilio' do
      incoming_message = build :inbound_twilio_message
      incoming_message['From'] = Subscriber.format_phone_number("(202) 486-6066")
      incoming_message['To'] = "+12025554545"
      incoming_message['Body'] = "testswitchto2 start"
      helper = IncomingMessageManager.new(incoming_message)
      expect(helper.from_phone == "+12024866066").to be_truthy
    end
  end

end

# params = {"ToCountry"=>"US", "ToState"=>"DC", "SmsMessageSid"=>"SM6982f4dd88bacc2b5b0fd39518a23ddd", "NumMedia"=>"0", "ToCity"=>"WASHINGTON", "FromZip"=>"20782", "SmsSid"=>"SM6982f4dd88bacc2b5b0fd39518a23ddd", "FromState"=>"DC", "SmsStatus"=>"received", "FromCity"=>"WASHINGTON", "Body"=>"testswitchto2 start", "FromCountry"=>"US", "To"=>"+12025171774", "ToZip"=>"20388", "NumSegments"=>"1", "MessageSid"=>"SM6982f4dd88bacc2b5b0fd39518a23ddd", "AccountSid"=>"AC96abab99e4c7074745084fd920d120f0", "From"=>"+12024866066", "ApiVersion"=>"2010-04-01", "controller"=>"twilio", "action"=>"callback"}
