class Invitation < ActiveRecord::Base

	belongs_to(:person) # people can invite other people ...
	belongs_to(:team) # ... into teams
	
	named_scope :unaccepted, :conditions => {:accepted => false}
	
end
