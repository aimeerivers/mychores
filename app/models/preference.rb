class Preference < ActiveRecord::Base


validates_numericality_of(:template_recurrence_interval, :only_integer => true)

	belongs_to(:person)
	
	def self.updatepassword(preference_to_update, new_password)
		preference_to_update.twitter_password = new_password.tr("A-Za-z", "N-ZA-Mn-za-m")
		preference_to_update.save
	end
	
	
end
