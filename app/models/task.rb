class Task < ActiveRecord::Base

  include ActionView::Helpers::TextHelper

  belongs_to(:list)
  validates_associated(:list)

  has_many(:completions) # task may have completion history
  belongs_to(:person) # this is for assignment

  belongs_to(:picture)

  validates_presence_of(:name)
  validates_length_of(:name, :maximum=>255)

  validates_numericality_of(:recurrence_interval, :only_integer => true, :greater_than => 0)

  validates_presence_of(:next_due)

  before_create :check_rotation
  before_update :check_rotation

  def short_name
    truncate(name)
  end
  
  def list_name
    return '' if list.nil?
    list.name
  end


  def describe_recurrence
    # This is called after every create and every update done through the edit screen.
    # Not called after a reschedule resulting in a save, however - there's no need.
    
    if self.one_off
      description = "One-off task"
    else
      description = case self.recurrence_interval
      when nil,0,1
        "Every #{self.recurrence_measure.chop}"
      when 2
        "Every other #{self.recurrence_measure.chop}"
      else
        "Every #{self.recurrence_interval} #{self.recurrence_measure}"
      end
      
      recur_on = self.recurrence_occur_on
      recur_on = self.recurrence_occur_on.split(",") if recur_on.is_a?(String)
      recur_on.map!(&:to_i)
      
      days_of_week = %W{Sunday Monday Tuesday Wednesday Thursday Friday Saturday}
      
      if recur_on.length == 1
        day = days_of_week[recur_on.first]
        description +=  " (#{day})"
      elsif recur_on.length == 6
        days_of_week_as_ints = (0..6).to_a
        day = days_of_week[(days_of_week_as_ints - recur_on).first]
        description += " (not #{day})"
      end
    end
    
    self.recurrence_description = description
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
      twitter = Twitter::Session.new(person)
      result = twitter.update(self)
      
      case result
      when Twitter::Success
        if person.status.blank?
          person.status = "Site Promoter"
          person.save
        end
        
        flash_message = "Task updated, and a post made to Twitter."
      when Twitter::Unauthorized
        flash_message = "Task updated, but Twitter update failed - please check Twitter password."
      when Twitter::ServiceError
        flash_message = "Task updated, but Twitter is currently not working. No post has been made to Twitter."
      when Twitter::Unavailable
        flash_message = "Task updated, but Twitter is currently unavailable. No post has been made to Twitter."
      when Twitter::Error
        flash_message = "Task updated, but Twitter update failed."
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
