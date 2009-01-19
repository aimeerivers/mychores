Given /^we already know the security code for (\w+)$/ do |name|
  person = Person.find_by_name(name)
  @code = person.code
end

Then /^the security code for (\w+) should have changed$/ do |name|
  person = Person.find_by_name(name)
  person.code.should_not == @code
end

Then /^that email should contain the correct password reset link for (\w+)$/ do |name|
  person = Person.find_by_name(name)
  @email.message.should =~ /http:\/\/www.mychores.co.uk\/admin\/resetpassword\/#{person.id}\?code=#{person.code}/m
end

