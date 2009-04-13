Given /^a person called '(\w+)' with login ID '(\w+)'$/ do |name, login|
  Person.create!(:name => name, :login => login, :email => "#{name}@test.com",
    :password => '12345', :password_confirmation => '12345', :preference => Preference.new)
end

Given /^an administrator called '(\w+)' with login ID '(\w+)'$/ do |name, login|
  Given "a person called '#{name}' with login ID '#{login}'"
  Person.last.update_attribute(:status, 'Site Creator')
end
