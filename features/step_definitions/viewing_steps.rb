Then /^I should see the text '(.*)'$/ do |text|
  response.body.should =~ /#{text}/m
end

Then /^I should NOT see the text '(.*)'$/ do |text|
  response.body.should_not =~ /#{text}/m
end

Then /^I should see a link to '(.+)'$/ do |link|
  response.should have_tag('a', link)
end

Then /^I should NOT see a link to '(.+)'$/ do |link|
  response.should_not have_tag('a', link)
end


Then /^the text field with id '(\w+)' should be filled in with '(.+)'$/ do |field_id, value|
  response.should have_tag('input[id=?][value=?]', field_id, value)
end








When /^I debug the page$/ do
  raise response.body
end

