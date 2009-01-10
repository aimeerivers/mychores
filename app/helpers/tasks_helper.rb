module TasksHelper
  def workload_display_select_options(person)
    display_list = [
      ["All tasks".t, "All tasks"], 
      ["Only my tasks".t, "Only my tasks"], 
      ["Only today's tasks".t, "Only today's tasks"], 
    ]
    person.teams.each do |team|
      team.memberships.each do |membership|
        display_list << ["Only " + team.name + ": " + membership.person.name, membership.person.id.to_s]
      end
    end
    display_list
  end
end
