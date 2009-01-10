Then /^the referrer ID for '(\w+)' should be set to '(\w+)'$/ do |login, referrer|
  person = Person.find_by_login(login)
  person.parent.should == Person.find_by_login(referrer)
end

