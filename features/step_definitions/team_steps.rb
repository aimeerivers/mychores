Given /^a team called '(.+)'$/ do |name|
  Team.create!(:name => name)
end

Given /^'(.+)' is a member of team '(.+)'$/ do |person, team|
  person = Person.find_by_name(person)
  team = Team.find_by_name(team)
  membership = Membership.create!(:person => person, :team => team, :confirmed => true)
end

