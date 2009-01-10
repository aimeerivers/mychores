Given /^I am not logged in$/ do
  visits '/admin/logout'
end

Given /^I am logged in as '(.+)'$/ do |person|
  person = Person.find_by_name(person)
  visit 'admin/login'
  fill_in 'Login ID', :with => person.login
  fill_in 'Password', :with => '12345'
  click_button 'Login'
end

