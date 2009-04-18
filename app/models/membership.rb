class Membership < ActiveRecord::Base

  belongs_to(:person) # people can be members ...
  belongs_to(:team) # ... of teams

  named_scope :confirmed, :conditions => {:confirmed => true}
  
  def person_name
    return '' if person.nil?
    person.name
  end
  
  def person_email
    return 'contact@mychores.co.uk' if person.nil?
    person.email
  end
  
  def team_name
    return '' if team.nil?
    team.name
  end

end
