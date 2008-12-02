Then /^I should see the text '(.*)'$/ do |text|
  response.body.should =~ /#{text}/m
end

Then /^I should NOT see the text '(.*)'$/ do |text|
  response.body.should_not =~ /#{text}/m
end

Then /^the text field with id '(\w+)' should be filled in with '(.+)'$/ do |field_id, value|
  response.should have_tag('input[id=?][value=?]', field_id, value)
end

