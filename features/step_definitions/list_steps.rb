Given /^a list '(.+)' for team '(.+)'$/ do |list, team|
  team = Team.find_by_name(team)
  list = List.create!(:name => list, :team => team)
end

