class Message < ActiveRecord::Base

	has_one(:person) # optional - can link to a person
	
	validates_length_of :name, :maximum => 40
	validates_presence_of :name
  
	validates_length_of :email, :maximum => 255
	validates_presence_of :email

end
