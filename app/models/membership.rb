class Membership < ActiveRecord::Base

	belongs_to(:person) # people can be members ...
	belongs_to(:team) # ... of teams
	
	named_scope :confirmed, :conditions => {:confirmed => true}
	
end
