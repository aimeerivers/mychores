require 'active_record'

class Team < ActiveRecord::Base

  attr_protected :code

has_many(:memberships, :dependent => :destroy)
has_many(:invitations) # links to invitations
has_many(:lists, :order => 'name asc', :dependent => :destroy) # each team has lists, in the heirarchy

belongs_to(:person) # owner/creator

validates_presence_of(:name)
validates_length_of(:name, :maximum=>25)


  def confirmed_members
    Person.find(memberships.confirmed.map(&:person_id))
  end
  
  def editable_by?(person)
    Membership.count(:conditions => {:team_id => id, :person_id => person.id, :confirmed => true}) >= 1
  end
  
  def member?(person)
    Membership.count(:conditions => {:team_id => id, :person_id => person.id, :confirmed => true}) >= 1
  end
  
  def deletable_by?(person)
    self.person == person
  end
  
  def owner_name
    return '' if person.nil?
    person.name
  end
  
  def owner_email
    return 'contact@mychores.co.uk' if person.nil?
    person.email
  end


protected
  
	before_create :create_code
	
	def create_code
		self.code = Person.sha1(self.name + Time.now.to_s)
	end

end
