require File.expand_path("../../config/boot", __FILE__)
require File.expand_path("../../config/environment", __FILE__)
require "clockwork"

include Clockwork

every(3.minutes, "Check if any channels are pending transmission") do
  TpartyScheduledMessageSender.perform_async
end

every(1.hour, "Send hourly subscriber activity reports") do
  SubscriberActivityReportSender.perform_async :hourly
end

every(1.day, "Send daily subscriber activity reports", at: "01:00") do
  SubscriberActivityReportSender.perform_async :daily
end


