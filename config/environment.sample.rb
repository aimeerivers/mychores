# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.gem 'recaptcha'
  config.gem 'RedCloth'
  config.gem 'ruby-openid', :lib => 'openid'

  config.action_controller.session = {
    :session_key => 'invent_something',
    :secret      => 'blah_de_blah_put_your_own'
  }
  config.action_controller.session_store = :active_record_store

  config.time_zone = 'London'
end

DAYSOFWEEK = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ]

AVAILABLEDAYS = [ "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th", "13th", "14th", "15th", "16th", "17th", "18th", "19th", "20th", "21st", "22nd", "23rd", "24th", "25th", "26th", "27th", "28th" ]

# ActionMailer settings:
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
	:address  => "mail.server.co.uk",
	:port  => 26, 
	:domain  => "www.server.co.uk",
	:user_name  => "mail_user_name",
	:password  => "and_password",
	:authentication  => :login
}

CGI::Session.expire_after 1.month

require 'will_paginate'

RCC_PUB = 'your_public_key_for_recaptcha'.freeze
RCC_PRIV = 'your_private_key_for_recaptcha'.freeze
