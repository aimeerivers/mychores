class Preference < ActiveRecord::Base


validates_numericality_of(:template_recurrence_interval, :only_integer => true)

	belongs_to(:person)
	
	def self.updatepassword(preference_to_update, new_password)
		preference_to_update.twitter_password = new_password.tr("A-Za-z", "N-ZA-Mn-za-m")
		preference_to_update.save
	end
	
	
	
	
	protected
    
	before_create :translate_times
	before_update :translate_times
  
  
	def translate_times
		# Change preference.email_time (varchar)
		# Into preference.email_time_gmt (time)
		# Using preference.person.timezone_name
		# updates whenever preferences are saved.
		mytimezone = TimeZone.new(self.person.timezone_name)
		self.email_time_gmt = mytimezone.local_to_utc(Time.parse(self.email_time))
		
		# do the same for Twitter receive time
		self.twitter_receive_time_gmt = mytimezone.local_to_utc(Time.parse(self.twitter_receive_time))
	end 

end
