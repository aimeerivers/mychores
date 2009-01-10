Given /^a task '(.+)' for list '(.+)'$/ do |task, list|
  list = List.find_by_name(list)
  task = Task.create!(:name => task, :list => list, :next_due => Date.today + 3)
end

Given /^the task '(.+)' is assigned to '(.+)'$/ do |task, person|
  task = Task.find_by_name(task)
  person = Person.find_by_name(person)
  task.update_attributes!({:person => person})
end

When /^I view the workload page$/ do
  visit '/tasks/workload'
end

Then /^I should see the task '(.+)'$/ do |task|
  task = Task.find_by_name(task)
  response.should have_tag('tr') do
    with_tag('td', /^#{task.list_name}/)
    with_tag('td', /^#{task.name}/)
  end
end

Then /^I should NOT see the task '(.+)'$/ do |task|
  response.should_not have_tag('td', /^#{task}/)
end

