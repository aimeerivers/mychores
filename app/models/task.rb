class Task < ActiveRecord::Base

belongs_to(:list)
validates_associated(:list)

has_many(:completions) # task may have completion history
belongs_to(:person) # this is for assignment

belongs_to(:picture)

validates_presence_of(:name)
validates_length_of(:name, :maximum=>30)

validates_numericality_of(:recurrence_interval, :only_integer => true)

validates_presence_of(:next_due)

before_create :check_rotation
before_update :check_rotation


	def describe_recurrence
	
		# This is called after every create and every update done through the edit screen.
		# Not called after a reschedule resulting in a save, however - there's no need.
	
		# Look out for bad integers!
		if !self.recurrence_interval
		  self.recurrence_interval = 1
		end
		if self.recurrence_interval < 1
			self.recurrence_interval = 1	
		end
	
		if self.one_off == true
			self.recurrence_description = "One-off task"
		else
			if self.recurrence_measure == 'days'
				if self.recurrence_interval == 1
					self.recurrence_description = "Every day"
				elsif self.recurrence_interval == 2
					self.recurrence_description = "Every other day"
				else
					self.recurrence_description = "Every " + self.recurrence_interval.to_s + " days"
				end
							
			elsif self.recurrence_measure == 'weeks'
				if self.recurrence_interval == 1
					self.recurrence_description = "Every week"
				else
					self.recurrence_description = "Every " + self.recurrence_interval.to_s + " weeks"
				end
				
							
			elsif self.recurrence_measure == 'months'
				if self.recurrence_interval == 1
					self.recurrence_description = "Every month"
				else
					self.recurrence_description = "Every " + self.recurrence_interval.to_s + " months"
				end
				
			end
			
			if self.recurrence_occur_on.length == 1
			
				self.recurrence_description += " ("
				
				if self.recurrence_occur_on.include?("0") then self.recurrence_description += "Sunday" end
				if self.recurrence_occur_on.include?("1") then self.recurrence_description += "Monday" end
				if self.recurrence_occur_on.include?("2") then self.recurrence_description += "Tuesday" end
				if self.recurrence_occur_on.include?("3") then self.recurrence_description += "Wednesday" end
				if self.recurrence_occur_on.include?("4") then self.recurrence_description += "Thursday" end
				if self.recurrence_occur_on.include?("5") then self.recurrence_description += "Friday" end
				if self.recurrence_occur_on.include?("6") then self.recurrence_description += "Saturday" end
				
				self.recurrence_description += ")"
				
			end
			
			
			if self.recurrence_occur_on.length == 6
				self.recurrence_description += " (not "
				
				if self.recurrence_occur_on.include?("0") == false then self.recurrence_description += "Sunday" end
				if self.recurrence_occur_on.include?("1") == false then self.recurrence_description += "Monday" end
				if self.recurrence_occur_on.include?("2") == false then self.recurrence_description += "Tuesday" end
				if self.recurrence_occur_on.include?("3") == false then self.recurrence_description += "Wednesday" end
				if self.recurrence_occur_on.include?("4") == false then self.recurrence_description += "Thursday" end
				if self.recurrence_occur_on.include?("5") == false then self.recurrence_description += "Friday" end
				if self.recurrence_occur_on.include?("6") == false then self.recurrence_description += "Saturday" end
				
				self.recurrence_description += ")"
				
			end
			
		end
	end
	
	
	
	
	def check_rotation
		if self.rotate == true and self.person_id.nil?
			# we have to assign it to a person
			# since we don't know who else to assign it to,
			# just find the first person to become a member of the team
			team = self.list.team
			firstperson = Membership.find(:first, :conditions => [ "team_id = ? and confirmed = 1", team.id])
			unless firstperson.nil?
				self.person_id = firstperson.person.id
			end
		end
	end
	
	
	
	
	def done(person, datecompleted, personcompleted, update_twitter)
	
		# Assumes that checks have already been made that this person is allowed
		# to update this task.
		
		# ALWAYS save the task after calling this function!
			
		# Create the completion record
		@completion = Completion.new(:person_id => personcompleted, :task_id => self.id, :date_completed => datecompleted, :source => 0)
		@completion.save
		
		
		
		
		# if it's a one-off task ...
		if self.one_off == true
			self.status = 'inactive'
		else
		
			# Reset the importance level
			self.current_importance = self.default_importance
			
			# Reschedule
			flash_message = self.reschedule(datecompleted)
			
			# if it's on rotating assignments work out the next assignee
			if self.rotate == true
				# by order of person id ascending (i.e. the order they signed up)
				# find the next person in the list
				nextassignee = Membership.find(:first, :conditions => [ "team_id = ? and confirmed = 1 and person_id > ?", self.list.team.id, personcompleted ], :order => "person_id ASC")
				
				# supposing there isn't anybody
				# then go back to the beginning again
				if nextassignee.nil?
					nextassignee = Membership.find(:first, :conditions => [ "team_id = ? and confirmed = 1", self.list.team.id ], :order => "person_id ASC")
				end
				
				self.person_id = nextassignee.person.id
				
			end
			
		end
		
		
		# Save before attempting a Twitter update
		self.save
		
		
		
		if update_twitter == true
			# Make a post to Twitter
					
			twitter_password = person.preference.twitter_password.tr("A-Za-z", "N-ZA-Mn-za-m")
	
			update_text = person.preference.twitter_update_string + " (www.mychores.co.uk)"
			update_text.gsub!('{TASK}', self.name)
			update_text.gsub!('{LIST}', self.list.name)
			update_text.gsub!('{TEAM}', self.list.team.name)
			
			# Apparently CGI escaping is only necessary for GET, not POST.
			# require 'cgi'
			# update_text = CGI::escape(update_text)
			
			
			begin
			
				url = URI.parse('http://twitter.com/statuses/update.xml')
				req = Net::HTTP::Post.new(url.path)
				req.basic_auth person.preference.twitter_email, twitter_password
				req.set_form_data({'status' => update_text})
				
				begin
					res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
					
					case res
					when Net::HTTPSuccess, Net::HTTPRedirection
						# OK
						if res.body.empty?
							flash_message = "Task updated, but Twitter is currently not working. No post has been made to Twitter."
						else
							flash_message = "Task updated, and a post made to Twitter."
							
							# Update their status if they've made a Twitter post.
							if person.status.nil? or person.status == ""
								person.status = "Site Promoter"
								person.save
								session[:person].status = "Site Promoter"
							end
							
						end
					else
						res.error!
						flash_message = "Task updated, but Twitter update failed."
					end
					
				rescue
					# In case of 401 unauthorised - ie wrong password
					flash_message = "Task updated, but Twitter update failed - please check Twitter password."
				end
				
				
			
			rescue SocketError
				# Twitter is currently unavailable
				flash_message = "Task updated, but Twitter is currently unavailable. No post has been made to Twitter."
				
			end
						
		end
		
		
		return flash_message
	end
	
	
	
	
	
	def reschedule(datecompleted)
	
		# ALWAYS save the task AFTER calling this function!
		
		# reset the next_due date of the task
		if self.recurrence_measure == 'days'
			# easy - just count on the number of days
			proposed_next_due = datecompleted + self.recurrence_interval.to_i
			
			
			
		elsif self.recurrence_measure == 'weeks'
			proposed_next_due = datecompleted + ((self.recurrence_interval.to_i) * 7)
			
			
			
		elsif self.recurrence_measure == 'months'
			# the day of month will be the same as the day it's completed
			target_day = datecompleted.mday
			
			# jump forward the number of months
			target_month = datecompleted.month + self.recurrence_interval.to_i
			target_year = datecompleted.year
			
			# supposing month has gone over 12 ...
			while target_month > 12
				target_month -= 12
				target_year += 1
			end
			
			# Be careful of months with fewer days
			case target_month
				when 2 then target_day = 28 if target_day > 28 # February
				when 4 then target_day = 30 if target_day > 30 # April
				when 6 then target_day = 30 if target_day > 30 # June
				when 9 then target_day = 30 if target_day > 30 # September
				when 11 then target_day = 30 if target_day > 30 # November
			end
			
			# Set the next due date
			proposed_next_due = Date.new(target_year, target_month, target_day)
				
		end
		
		# Having obtained a proposed_next_due date,
		# See if it matches one of the days that they want the task done.
		
		successful = false
		
		if self.recurrence_occur_on.include?(proposed_next_due.wday.to_s)
			self.next_due = proposed_next_due
			successful = true
			
		else
			# Bounce around the proposed date, trying to find one that is acceptable.
			for loop in 1..14
				if successful == false
				
					if loop.odd?
						proposed_next_due -= loop
					else
						proposed_next_due += loop
					end
					
					if self.recurrence_occur_on.include?(proposed_next_due.wday.to_s)
						if proposed_next_due > datecompleted
							self.next_due = proposed_next_due
							successful = true
						end
					end
					
				end
			end
		end
		
		self.escalation_date = self.next_due + 1
		
		
	 	flash_message = "Task updated."
	 	
	 	return flash_message
	end
	
	
protected
	
	def before_destroy
	   # Due to constraints, deleting a task will delete all completion history.
	   # Since this will mess up statistics, we'll change the completions to point to a virtual task
	   # This virtual task is owned by a virtual person.
	   
	   @completions = self.completions
	   for completion in @completions
	     completion.person_id = 649 # deletedperson
	     completion.task_id = 15335 # deletedtask
	     completion.save
	   end
	   
	end
	

end
