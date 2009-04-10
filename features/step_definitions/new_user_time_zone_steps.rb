Then /^I should see my email notification time set to (\d\d):(\d\d)$/ do |hour, minute|
  response.should have_tag('select#preference_email_time_4i') do
    with_tag('option[value=?][selected=selected]', hour)
  end
end

Then /^the email time in the database should be set to (\d\d):(\d\d)$/ do |hour, minute|
  p = Preference.last
  email_time = p.email_time_before_type_cast
  email_time.should =~ / #{hour}:#{minute}:00$/
end
