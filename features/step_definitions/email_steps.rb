Given /^there are no emails waiting to be sent$/ do
  ActionMailer::Base.deliveries.clear
  Email.delete_all
end

Then /^there should be (\d+) emails? on the queue$/ do |number|
  Email.count.should == number.to_i
  @email = Email.last unless number.to_i < 1
end

Then /^that email should be addressed to '(.+)'$/ do |address|
  @email.to.should == address
end

Then /^that email should have the subject '(.+)'$/ do |subject|
  @email.subject.should == subject
end

Then /^that email should contain '(.+)' in the body$/ do |content|
  @email.message.should =~ /#{content}/mi
end

