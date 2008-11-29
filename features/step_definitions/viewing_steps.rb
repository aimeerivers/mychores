Then /^I should see the text '(.*)'$/ do |text|
  response.body.should =~ /#{text}/m
end

Then /^I should NOT see the text '(.*)'$/ do |text|
  response.body.should_not =~ /#{text}/m
end
