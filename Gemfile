# rubocop:disable StringLiterals
source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '5.0.0.1'
gem 'pg'
gem 'jquery-rails'
gem 'simple_form'
gem 'devise'
gem 'bootstrap-sass'
gem 'figaro'

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'slim-rails'

gem 'json'
gem 'thin'
gem 'foreman'

gem 'paperclip'
gem 'aws-sdk'

gem 'draper', '>= 3.0.0.pre1'

gem 'twilio-ruby'

gem 'will_paginate-bootstrap'

gem 'sidekiq'
gem 'sidekiq-failures'
gem 'sinatra', github: 'sinatra/sinatra'
gem 'clockwork'

gem 'cocoon'
gem 'chronic'

gem 'statsd-instrument'

gem 'recurring_select', git: 'https://github.com/clthck/recurring_select.git', branch: 'add_hour_and_minute_to_rules'
gem 'datetimepicker-rails', git: 'https://github.com/zpaulovics/datetimepicker-rails.git', tag: 'v1.0.0'
gem 'select2-rails'
gem 'momentjs-rails'
gem 'moment_timezone-rails'

gem 'paranoia', github: 'rubysherpas/paranoia', branch: 'rails5'

gem 'remotipart', github: 'mshibuya/remotipart'
gem 'rails_admin', '>= 1.0.0.rc'

group :development, :test do
  # Use RSpec for testing suite.
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'factory_girl_rails'
  gem 'guard-rspec'
  gem 'rspec-preloader'
  # Instafailing RSpec formatter that uses a progress bar instead of a string of letters and dots as feedback.
  gem 'fuubar'
  gem 'annotate'
  gem 'database_cleaner'
  gem 'meta_request'
  # Call `binding.pry` anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'
  gem 'test-unit'
  gem 'faker'
  gem 'timecop'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'simplecov', require: false
  gem 'recursive-open-struct'
  gem 'rack-test', require: 'rack/test'
  gem 'rails-controller-testing'
end

group :production do
  gem 'rails_12factor'
end
