class Newsletter < ActiveRecord::Base

	
	validates_length_of :title, :maximum => 50
	validates_presence_of :title
  
	validates_presence_of :content

end
