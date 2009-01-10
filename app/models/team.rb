require 'active_record'

class Team < ActiveRecord::Base

has_many(:memberships) # links to members
has_many(:invitations) # links to invitations
has_many(:lists, :order => 'name asc') # each team has lists, in the heirarchy

belongs_to(:person) # owner/creator

validates_presence_of(:name)
validates_length_of(:name, :maximum=>25)


  def confirmed_members
    Person.find(memberships.confirmed.map(&:person_id))
  end


protected
  
	before_create :create_code
	
	def create_code
		self.code = Person.sha1(self.name + Time.now.to_s)
	end

end
