# Commonly used webrat steps
# http://github.com/brynary/webrat

When /^I click on '(.*)'$/ do |link|
  click_link link
end

When /^I click the '(.*)' button$/ do |name|
  click_button name
end

When /^I visit the page (.+)$/ do |url|
  visit url
end

When /^I visit the welcome page$/ do
  visit welcome_path
end





When /^I follow '(.*)'$/ do |link|
  click_link(link)
end

When /^I fill in '(.*)' with '(.*)'$/ do |field, value|
  fill_in(field, :with => value) 
end

When /^I select '(.*)' from '(.*)'$/ do |value, field|
  select(value, :from => field) 
end

When /^I check '(.*)'$/ do |field|
  check(field) 
end

When /^I uncheck '(.*)'$/ do |field|
  uncheck(field) 
end

When /^I choose '(.*)'$/ do |field|
  choose(field)
end

When /^I attach the file at '(.*)' to '(.*)' $/ do |path, field|
  attach_file(field, path)
end

Then /^I should see '(.*)'$/ do |text|
  response.body.should =~ /#{text}/m
end

Then /^I should not see '(.*)'$/ do |text|
  response.body.should_not =~ /#{text}/m
end

Then /^the '(.*)' checkbox should be checked$/ do |label|
  field_labeled(label).should be_checked
end
