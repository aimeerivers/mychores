module TasksHelper
  def workload_display_select_options(person)
    display_list = [
      ["All tasks".t, "All tasks"], 
      ["Only my tasks".t, "Only my tasks"], 
      ["Only today's tasks".t, "Only today's tasks"], 
    ]
    person.fellow_team_members.each do |person|
      display_list << ["Only #{person.name}'s tasks", person.id]
    end
    display_list
  end
end
