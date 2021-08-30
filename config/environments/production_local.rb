require "pry"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false
  config.log_level = :info
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: "localhost:3000" }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: "liveinspired.herokuapp.com" }
  ActionMailer::Base.smtp_settings = {
    address: "smtp.sendgrid.net",
    port: "25",
    authentication: :plain,
    user_name: ENV["SENDGRID_USERNAME"],
    password: ENV["SENDGRID_PASSWORD"],
    domain: ENV["SENDGRID_DOMAIN"],
  }

  # Do not compress assets
  config.assets.js_compressor = false
  config.assets.css_compressor = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.time_zone = "Eastern Time (US & Canada)"
end
