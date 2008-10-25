#!/usr/local/bin/ruby

require File.dirname(__FILE__) + '/../config/environment'
logger = RAILS_DEFAULT_LOGGER

@emails = Email.find(:all, :conditions => "sent = 0")
for email in @emails
	Notifier::deliver_outbound_email(email)
	
	email.sent = 1
	email.save
end