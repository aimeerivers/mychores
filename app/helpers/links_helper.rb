module LinksHelper
  
  def link_to_team(team, css_class)
    style = (team.use_colour?) ? "background-color:##{team.colour}; color:##{team.text_colour};" : ''
    link_to(h(team.name), team_path(team), :class => "#{css_class} team", :style => style)
  end
  
end