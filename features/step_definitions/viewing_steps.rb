Then /^we should see the text (.*)$/ do |text|
  response.body.should =~ /#{text}/m
end
