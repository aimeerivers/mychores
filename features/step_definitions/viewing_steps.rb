Then /^we should see the text '(.*)'$/ do |text|
  response.body.should =~ /#{text}/m
end

Then /^we should NOT see the text '(.*)'$/ do |text|
  response.body.should_not =~ /#{text}/m
end
