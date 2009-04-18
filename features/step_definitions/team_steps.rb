Given /^a team called '(.+)'$/ do |name|
  Team.create!(:name => name)
end

Given /^'(.+)' is a member of team '(.+)'$/ do |person, team|
  person = Person.find_by_name(person)
  team = Team.find_by_name(team)
  membership = Membership.create!(:person => person, :team => team, :confirmed => true)
end

Given /^'(.+)' is the owner of team '(.+)'$/ do |person, team|
  person = Person.find_by_name(person)
  team = Team.find_by_name(team)
  team.person = person
  team.save
end

When /^I view the team '(.+)'$/ do |teamname|
  team = Team.find_by_name(teamname)
  visit team_path(team)
end

When /^I try to edit the team '(.+)'$/ do |teamname|
  team = Team.find_by_name(teamname)
  visit edit_team_path(team)
end

When /^I try to update the team '(.+)'$/ do |teamname|
  team = Team.find_by_name(teamname)
  visit team_path(team), :put
end

When /^I try to delete the team '(.+)'$/ do |teamname|
  team = Team.find_by_name(teamname)
  visit team_path(team), :delete
end

When /^I try to remove myself from '(.+)'$/ do |teamname|
  team = Team.find_by_name(teamname)
  visit leave_team_path(team), :delete
end


Then /^(\w+) should be a member of the team '(.+)'$/ do |name, team|
  p = Person.find_by_name(name)
  t = Team.find_by_name(team)
  p.confirmed_teams.include?(t).should be_true
end

Then /^(\w+) should NOT be a member of the team '(.+)'$/ do |name, team|
  p = Person.find_by_name(name)
  t = Team.find_by_name(team)
  p.confirmed_teams.include?(t).should be_false
end

Then /^the team should have background colour '(.+)' and text colour '(.+)'$/ do |b, t|
  response.should have_tag('a.team[style=?]', "background-color:##{b}; color:##{t};")
end

Then /^the team should have no background colour$/ do
  response.should have_tag('a.team')
  response.should_not have_tag('a.team[style=?]', "background-color:#3F2A44; color:#D2AFAF;")
end


