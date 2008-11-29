require 'digest/sha1'
require 'active_record'

# this model expects a certain database layout and its based on the name/login pattern. 
class Person < ActiveRecord::Base

  composed_of :tz, :class_name => 'TZInfo::Timezone', :mapping => %w(time_zone time_zone)

  has_many(:completions) # has completed tasks
  has_many(:memberships) # may be a member of teams
  has_many(:tasks) # may have task assignments
  has_many(:teams) # is owner/creator of teams
  has_many(:invitations) # may have sent invitations to many people
  has_many(:tips) # may have contributed one or more tips
  has_many(:pictures) # any pictures this person has uploaded
	
  has_one(:preference)
	
  # parent-child relationship
  belongs_to(:parent, :class_name => "Person", :foreign_key => "parent_id")
  has_many(:children, :class_name => "Person", :foreign_key => "parent_id")
  
  
  
  
  validates_length_of :login, :within => 3..40
  validates_uniqueness_of :login, :case_sensitive => false
  validates_format_of :login, :with => /^[\w-]+$/, :message => "can only contain letters and numbers"

  validates_length_of :password, :within => 5..40
  validates_presence_of :password
  validates_confirmation_of :password, :on => :create
  validates_presence_of :password_confirmation, :on => :create
  
  validates_length_of :name, :maximum => 40
  validates_presence_of :name
  
  validates_length_of :email, :maximum => 255
  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "seems to be invalid"
	
	


  # Please change the salt to something else, 
  # Every application should use a different one 
  @@salt = 'Planner'
  cattr_accessor :salt

  # Authenticate a user. 
  #
  # Example:
  #   @person = Person.authenticate('bob', 'bobpass')
  #
  def self.authenticate(login, pass)
    find(:first, :conditions => ["login = ? AND password = ? AND usertype = 1", login, sha1(pass)])
  end  

  def self.updatepassword(person_to_update, new_password)
    person_to_update.password = sha1(new_password)
    person_to_update.save
  end
  
  
  # Work out if the referrer (parent) entered is valid:
  
  def referrer
  end
  
  def referrer=(field)
    return if field.empty?
    write_attribute("referrer", field)
    self.parent = Person.find_by_login(field)
    @referrer_invalid = true if self.parent.nil?
  end
  
  
  
  
  # check captcha code
  #def validation
  #end
  
  #def validation=(field)
  #		write_attribute("validation", field)
  #  	@captcha_invalid = true unless field == "H6a38G"
  #end
  
  
  
  
  
  
  
  def signup_new_user(code)
    
    @mytimezone = TimeZone.new(self.timezone_name)
    @todaysdate = Date.parse(@mytimezone.today().to_s)
    
    # Generate a new email verification code
    self.email_code = Person.sha1(self.email + Time.now.to_s)
    self.email_verified = false
    self.save
    
    
    
    unless code.nil?
      # Search by code and email address in the invitations list
      @teaminvitations = Invitation.find(:all, :conditions => [ "(email = ? or code = ?) and accepted = 0", self.email, code ])
    else
      # Search for the email address in the invitations list
      @teaminvitations = Invitation.find(:all, :conditions => [ "email = ? and accepted = 0", self.email ])
    end
    
    unless @teaminvitations.empty?
      # Found some teams to join them up with!
    	
      for teaminvitation in @teaminvitations
    	
        # create a link in memberships table
        validitykey = Person.sha1(self.name + Time.now.to_s)
        @membership = Membership.new(
          :person_id => self.id,
          :team_id => teaminvitation.team.id,
          :invited => true,
          :confirmed => true,
          :validity_key => validitykey)
        @membership.save
    		
        # update the invitation record to indicate that the person accepted and joined
        teaminvitation.accepted = true
        teaminvitation.save
      end
    	
      
      
      # Send an email
      @email = Email.new
      @email.subject = "Welcome to MyChores"
      @email.message = "Dear " + self.name + ",

Welcome to MyChores.co.uk! "

      if self.openid_url.nil?
        @email.message += "Your login is " + self.login + "."
      else
        @email.message += "Your OpenID login is " + self.openid_url + "."
      end
      
      @email.message += "
      
Since you were invited to join a team, you have been automatically added into that team. You are able to remove yourself from it if you wish. You are also able to create your own teams.
  
Please follow this link to verify your email address and confirm your email preferences. We will not send you unwanted emails, nor will we ever pass on your email address to anyone else.
http://www.mychores.co.uk/subscription/" + self.id.to_s + "/" + self.email_code + "/email/on

If you have any problems please email contact@mychores.co.uk or use the contact form on the site.

Thanks - enjoy!

http://www.mychores.co.uk"
      @email.to = self.email
      @email.save
      # Notifier::deliver_signup_thanks_joined_team(self) # notice the `deliver_` prefix
    	
      
    	
      return 1 # (to indicate auto signup)
    	
    	
    else
      # it's a newbie with no prior invitations.
      # create them some tasks to get started
    
      
      # Create a starter team
      teamname = "Household"
      teamdescription = "This is your default team, set up for you when you registered. Feel free to edit it and invite other people to join. Alternatively you can create new teams if you prefer."
      @team = Team.new(:name => teamname, :description => teamdescription, :person_id => self.id)
      @team.save
      
      # Make the newly registered person a member of their own team
      validitykey = Person.sha1(self.name + Time.now.to_s)
      @membership = Membership.new(:person_id => self.id, :team_id => @team.id, :confirmed => 1, :validity_key => validitykey)
      @membership.save
      
      # General list
      @templist = List.new
      @templist.name = 'General'
      @templist.description = "A list for general things that need to be done around the home"
      @templist.team_id = @team.id
      @templist.save
		
      # Water plants
      @temptask = Task.new
      @temptask.name = 'Water plants'
      @temptask.description = "Water all the plants in the house"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '2'
      @temptask.recurrence_measure = 'days'
      @temptask.next_due = @todaysdate
      @temptask.default_importance = 3
      @temptask.current_importance = 3
      @temptask.describe_recurrence
      @temptask.picture_id = 20
      @temptask.save
		
      # Sweep/vacuum
      @temptask = Task.new
      @temptask.name = 'Sweep/vacuum floors'
      @temptask.description = "Sweep or vacuum all floors throught the house"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '1'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 3
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 19
      @temptask.save
		
      # Laundry
      @temptask = Task.new
      @temptask.name = 'Laundry'
      @temptask.description = "Alternate between dark and light washes, or as needed"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '4'
      @temptask.recurrence_measure = 'days'
      @temptask.next_due = @todaysdate + 2
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 37
      @temptask.save
		
      # Put away things out of place
      @temptask = Task.new
      @temptask.name = 'Put away things out of place'
      @temptask.description = "Find anything that is not where it should be and put it away"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '1'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 1
      @temptask.default_importance = 3
      @temptask.current_importance = 3
      @temptask.describe_recurrence
      @temptask.picture_id = 14
      @temptask.save
		
      # Dust surfaces
      @temptask = Task.new
      @temptask.name = 'Dust surfaces'
      @temptask.description = "All the furniture and hard surfaces throughout the house need to be dusted"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '1'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 2
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 8
      @temptask.save
		
      # Open windows
      @temptask = Task.new
      @temptask.name = 'Open windows'
      @temptask.description = "Open all the windows and give the home a good airing"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '1'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 5
      @temptask.default_importance = 2
      @temptask.current_importance = 2
      @temptask.describe_recurrence
      @temptask.picture_id = 12
      @temptask.save
		
		
		
      # Living Room
      @templist = List.new
      @templist.name = 'Living Room'
      @templist.description = "A list for the tasks that need to be done in the living room"
      @templist.team_id = @team.id
      @templist.save
		
      # Plump cushions
      @temptask = Task.new
      @temptask.name = 'Plump cushions'
      @temptask.description = "Are the sofa cushions looking flat? Plump them up again!"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '5'
      @temptask.recurrence_measure = 'days'
      @temptask.next_due = @todaysdate
      @temptask.default_importance = 2
      @temptask.current_importance = 2
      @temptask.describe_recurrence
      @temptask.picture_id = 13
      @temptask.save
		
      # Clean television & stereo
      @temptask = Task.new
      @temptask.name = 'Clean television & stereo'
      @temptask.description = "They get messy - time to give them a good clean"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '4'
      @temptask.recurrence_measure = 'months'
      @temptask.any_date = true
      target_day = 5
      target_month = @todaysdate.month + 3
      if target_month > 12
        target_month -= 12
        target_year = @todaysdate.year + 1
      else
        target_year = @todaysdate.year
      end
      @temptask.next_due = Date.new(target_year, target_month, target_day)
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 9
      @temptask.save
		
		
		
      # Bathroom
      @templist = List.new
      @templist.name = 'Bathroom'
      @templist.description = "A list for the tasks that need to be done in the bathroom"
      @templist.team_id = @team.id
      @templist.save
		
      # Clean & scrub bath
      @temptask = Task.new
      @temptask.name = 'Clean & scrub bath'
      @temptask.description = "Make the bath shine again"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '2'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 4
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 28
      @temptask.save
		
      # Clean toilet
      @temptask = Task.new
      @temptask.name = 'Clean toilet'
      @temptask.description = "Not a nice task but it needs to be done!"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '1'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 4
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 6
      @temptask.save
		
      # Change towels
      @temptask = Task.new
      @temptask.name = 'Change towels'
      @temptask.description = "On the same day as you clean the bath, change the bathroom towels"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '2'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 4
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 3
      @temptask.save
		
		
		
      # Bedroom
      @templist = List.new
      @templist.name = 'Bedroom'
      @templist.description = "A list for the tasks that need to be done in the bedroom"
      @templist.team_id = @team.id
      @templist.save
		
      # Change bed sheets
      @temptask = Task.new
      @temptask.name = 'Change bed sheets'
      @temptask.description = "Strip the bed and give it fresh sheets"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '2'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 5
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 2
      @temptask.save
		
      # Turn mattress
      @temptask = Task.new
      @temptask.name = 'Turn mattress'
      @temptask.description = "Time to turn the mattress over and sleep on the other side"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '6'
      @temptask.recurrence_measure = 'months'
      @temptask.any_date = true
      target_day = 13
      target_month = @todaysdate.month + 4
      if target_month > 12
        target_month -= 12
        target_year = @todaysdate.year + 1
      else
        target_year = @todaysdate.year
      end
      @temptask.next_due = Date.new(target_year, target_month, target_day)
      @temptask.default_importance = 3
      @temptask.current_importance = 3
      @temptask.describe_recurrence
      @temptask.picture_id = 18
      @temptask.save
		
		
		
      # Kitchen
      @templist = List.new
      @templist.name = 'Kitchen'
      @templist.description = "A list for the tasks that need to be done in the kitchen"
      @templist.team_id = @team.id
      @templist.save
		
      # Scrub & disinfect sink
      @temptask = Task.new
      @temptask.name = 'Scrub & disinfect sink'
      @temptask.description = "Free the kitchen sink of limescale and make it shine"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '1'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 6
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 5
      @temptask.save
		
      # Wipe appliances
      @temptask = Task.new
      @temptask.name = 'Wipe appliances'
      @temptask.description = "With a damp cloth, quickly wipe down the oven, refrigerator, freezer, washing machine, dishwasher, microwave ..."
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '2'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 6
      @temptask.default_importance = 3
      @temptask.current_importance = 3
      @temptask.describe_recurrence
      @temptask.picture_id = 21
      @temptask.save
		
      # Empty & clean bin
      @temptask = Task.new
      @temptask.name = 'Empty & clean bin'
      @temptask.description = "Wash out the bin with some disinfectant"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '3'
      @temptask.recurrence_measure = 'weeks'
      @temptask.any_day = true
      @temptask.next_due = @todaysdate + 13
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 10
      @temptask.save
		
      # Clean cupboards & pantry
      @temptask = Task.new
      @temptask.name = 'Clean cupboards & pantry'
      @temptask.description = "Take everything out of the cupboards and pantry, and wash the shelves thoroughly. Wipe down the doors to finish."
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '6'
      @temptask.recurrence_measure = 'months'
      @temptask.any_date = true
      target_day = 23
      target_month = @todaysdate.month + 1
      if target_month > 12
        target_month -= 12
        target_year = @todaysdate.year + 1
      else
        target_year = @todaysdate.year
      end
      @temptask.next_due = Date.new(target_year, target_month, target_day)
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 4
      @temptask.save
		
      # Clean oven thoroughly
      @temptask = Task.new
      @temptask.name = 'Clean oven thoroughly'
      @temptask.description = "This is easy with the right equipment - look in your supermarket or search online"
      @temptask.list_id = @templist.id
      @temptask.recurrence_interval = '6'
      @temptask.recurrence_measure = 'months'
      @temptask.any_date = true
      target_day = 18
      target_month = @todaysdate.month + 2
      if target_month > 12
        target_month -= 12
        target_year = @todaysdate.year + 1
      else
        target_year = @todaysdate.year
      end
      @temptask.next_due = Date.new(target_year, target_month, target_day)
      @temptask.default_importance = 4
      @temptask.current_importance = 4
      @temptask.describe_recurrence
      @temptask.picture_id = 27
      @temptask.save
		
      
      #flash[:notice] = "Welcome to MyChores! A few tasks have been created for you to get you started."
      #redirect_back_or_default :controller => 'tasks', :action => 'workload'
      #redirect_to :controller => 'admin', :action => 'welcome'
      
      # Send an email
      @email = Email.new
      @email.subject = "Welcome to MyChores"
      @email.message = "Dear " + self.name + ",

Welcome to MyChores.co.uk! "

      if self.openid_url.nil?
        @email.message += "Your login is " + self.login + "."
      else
        @email.message += "Your OpenID login is " + self.openid_url + "."
      end
      
      @email.message += "

A few tasks have been created to get you started. You are welcome to change them, add to them, remove them - whatever works for you personally. You can have as many tasks as you like - there's no limit.

A team has been created for you. Currently you are the only member, but you can invite other people to join the team and help you with your chores.
  
Please follow this link to verify your email address and confirm your email preferences. We will not send you unwanted emails, nor will we ever pass on your email address to anyone else.
http://www.mychores.co.uk/subscription/" + self.id.to_s + "/" + self.email_code + "/email/on

If you have any problems please email contact@mychores.co.uk or use the contact form on the site.

Thanks - enjoy!

http://www.mychores.co.uk"
      @email.to = self.email
      @email.save
      # Notifier::deliver_signup_thanks(self) # notice the `deliver_` prefix
    end
    	
    return 0 # (to indicate new signup)
  
  end
  
  
  
  
  
  
  
  
  

  protected

  # Apply SHA1 encryption to the supplied password. 
  # We will additionally surround the password with a salt 
  # for additional security. 
  def self.sha1(pass)
    Digest::SHA1.hexdigest("#{salt}--#{pass}--")
  end
    
  before_create :crypt_password, :create_code
  before_update :create_code
  
  # Before saving the record to database we will crypt the password 
  # using SHA1. 
  # We never store the actual password in the DB.
  def crypt_password
    write_attribute "password", self.class.sha1(password)
  end
  
  # before_update :crypt_unless_empty
  # don't do it cos it doesn't work! Use self.updatepassword when password is to be changed!
  
  # If the record is updated we will check if the password is empty.
  # If its empty we assume that the user didn't want to change the
  # password and just reset it to the old value.
  def crypt_unless_empty
    if password.empty?      
      person = self.class.find(self.id)
      self.password = person.password
    else
      write_attribute "password", self.class.sha1(password)
    end        
  end  
  
  
  def create_code
    # provides an emergency validation code if someone forgets their password.
    # updates whenever password or preferences are changed.
    self.code = self.class.sha1(self.name + Time.now.to_s)
		
    # I also want to know when midnight occurs for each person
    mytimezone = TimeZone.new(self.timezone_name)
    self.midnight_gmt = mytimezone.local_to_utc(Time.parse("00:00"))
  end
	

	
  
  
  
  # an extra check for the referrer (parent):
  # and for the captcha code:
  def validate
    #if @captcha_invalid
    #    errors.add(:validation, "code is incorrect; please try again (it's case-sensitive)")
    #	@captcha_invalid = nil
    #end
    if @referrer_invalid
      errors.add(:referrer, "is not recognised; please check again or leave it blank")
      @referrer_invalid = nil
    end
  end
  
  
  

end
