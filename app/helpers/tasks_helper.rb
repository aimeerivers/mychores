module TasksHelper
  def workload_display_select_options(person)
    display_list = [
      ["All tasks", "All tasks"], 
      ["Only my tasks", "Only my tasks"], 
      ["Only today's tasks", "Only today's tasks"], 
    ]
    person.fellow_team_members.each do |person|
      display_list << ["Only #{person.name}'s tasks", person.id.to_s]
    end
    display_list
  end
end
