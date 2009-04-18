class Membership < ActiveRecord::Base

  belongs_to(:person) # people can be members ...
  belongs_to(:team) # ... of teams

  named_scope :confirmed, :conditions => {:confirmed => true}
  named_scope :unconfirmed, :conditions => {:confirmed => false}
  
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
  
  def editable_by?(person)
    return true if self.person == person && invited?
    team.member?(person)
  end
  
  def deletable_by?(person)
    return false if team.owned_by?(self.person)
    return true if self.person == person
    team.member?(person)
  end

end
