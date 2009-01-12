require 'digest/sha1'
require 'active_record'

# this model expects a certain database layout and its based on the name/login pattern. 
class Person < ActiveRecord::Base

  attr_protected :status

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
  validates_confirmation_of :password, :on => :create
  
  validates_length_of :name, :maximum => 40
  validates_presence_of :name
  
  validates_length_of :email, :maximum => 255
  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "seems to be invalid", :unless => Proc.new { |user| user.email.blank? }
	
	


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
      
      
      
      default_tasks = [
        {:list_name => 'General', :description => 'A list for general things that need to be done around the home', :tasks => [
        
          {:name => 'Water plants', :description => 'Water all the plants in the house', :recurrence_interval => 2, :recurrence_measure => 'days', :next_due => @todaysdate, :default_importance => 3, :current_importance => 3, :picture_id => 20},
          
          {:name => 'Sweep/vacuum floors', :description => 'Sweep or vacuum all floors throughout the house', :recurrence_interval => 1, :recurrence_measure => 'weeks', :next_due => @todaysdate + 3, :default_importance => 4, :current_importance => 4, :picture_id => 19},
          
          {:name => 'Laundry', :description => 'Alternate between dark and light washes, or as needed', :recurrence_interval => 4, :recurrence_measure => 'days', :next_due => @todaysdate + 2, :default_importance => 4, :current_importance => 4, :picture_id => 37},
          
          {:name => 'Put away things out of place', :description => 'Find anything that is not where it should be and put it away', :recurrence_interval => 1, :recurrence_measure => 'weeks', :next_due => @todaysdate + 1, :default_importance => 3, :current_importance => 3, :picture_id => 14},
          
          {:name => 'Dust surfaces', :description => 'All the furniture and hard surfaces throughout the house need to be dusted', :recurrence_interval => 1, :recurrence_measure => 'weeks', :next_due => @todaysdate + 2, :default_importance => 4, :current_importance => 4, :picture_id => 8},
          
          {:name => 'Open windows', :description => 'Open all the windows and give the home a good airing', :recurrence_interval => 1, :recurrence_measure => 'weeks', :next_due => @todaysdate + 5, :default_importance => 2, :current_importance => 2, :picture_id => 12}
        ]},
        
        
        
        {:list_name => 'Living Room', :description => 'A list for the tasks that need to be done in the living room', :tasks => [
          
          {:name => 'Plump cushions', :description => 'Are the sofa cushions looking flat? Plump them up again!', :recurrence_interval => 5, :recurrence_measure => 'days', :next_due => @todaysdate, :default_importance => 2, :current_importance => 2, :picture_id => 13},
          
          {:name => 'Clean television & stereo', :description => 'They get messy - time to give them a good clean', :recurrence_interval => 4, :recurrence_measure => 'months', :next_due => @todaysdate + 3.months, :default_importance => 4, :current_importance => 4, :picture_id => 9}
        ]},
        
        
        
        {:list_name => 'Bathroom', :description => 'A list for the tasks that need to be done in the bathroom', :tasks => [
          
          {:name => 'Clean & scrub bath', :description => 'Make the bath shine again', :recurrence_interval => 2, :recurrence_measure => 'weeks', :next_due => @todaysdate + 4, :default_importance => 4, :current_importance => 4, :picture_id => 28},
          
          {:name => 'Clean toilet', :description => 'Not a nice task but it needs to be done!', :recurrence_interval => 1, :recurrence_measure => 'weeks', :next_due => @todaysdate + 4, :default_importance => 4, :current_importance => 4, :picture_id => 6},
          
          {:name => 'Change towels', :description => 'On the same day as you clean the bath, change the bathroom towels', :recurrence_interval => 2, :recurrence_measure => 'weeks', :next_due => @todaysdate + 4, :default_importance => 4, :current_importance => 4, :picture_id => 3}
        ]},
        
        
        
        {:list_name => 'Bedroom', :description => 'A list for the tasks that need to be done in the bedroom', :tasks => [
          
          {:name => 'Change bed sheets', :description => 'Strip the bed and give it fresh sheets', :recurrence_interval => 2, :recurrence_measure => 'weeks', :next_due => @todaysdate + 5, :default_importance => 4, :current_importance => 4, :picture_id => 2},
          
          {:name => 'Turn mattress', :description => 'Time to turn the mattress over and sleep on the other side', :recurrence_interval => 6, :recurrence_measure => 'months', :next_due => @todaysdate + 4.months, :default_importance => 3, :current_importance => 3, :picture_id => 18}
        ]},
        
        
        
        {:list_name => 'Kitchen', :description => 'A list for the tasks that need to be done in the kitchen', :tasks => [
          
          {:name => 'Scrub & disinfect sink', :description => 'Free the kitchen sink of limescale and make it shine', :recurrence_interval => 1, :recurrence_measure => 'weeks', :next_due => @todaysdate + 6, :default_importance => 4, :current_importance => 4, :picture_id => 5},
          
          {:name => 'Wipe appliances', :description => 'With a damp cloth, quickly wipe down the oven, refrigerator, freezer, washing machine, dishwasher, microwave ...', :recurrence_interval => 2, :recurrence_measure => 'weeks', :next_due => @todaysdate + 6, :default_importance => 3, :current_importance => 3, :picture_id => 21},
          
          {:name => 'Empty & clean bin', :description => 'Wash out the bin with disinfectant', :recurrence_interval => 3, :recurrence_measure => 'weeks', :next_due => @todaysdate + 13, :default_importance => 4, :current_importance => 4, :picture_id => 10},
          
          {:name => 'Clean cupboards & pantry', :description => 'Take everything out of the cupboards and pantry, and wash the shelves thoroughly. Wipe down the doors to finish.', :recurrence_interval => 6, :recurrence_measure => 'months', :next_due => @todaysdate + 5.weeks, :default_importance => 4, :current_importance => 4, :picture_id => 4},
          
          {:name => 'Clean oven thoroughly', :description => 'This is easy with the right equipment - look in your supermarket or check the tips on MyChores.', :recurrence_interval => 6, :recurrence_measure => 'months', :next_due => @todaysdate + 2.months, :default_importance => 4, :current_importance => 4, :picture_id => 27}
        ]}
      ]
      
      
      
      default_tasks.each do |list|
        @templist = List.new(:name => list[:list_name], :description => list[:description], :team_id => @team.id)
        @templist.save
        list[:tasks].each do |task|
          @temptask = Task.new(task)
          @temptask.list_id = @templist.id
          @temptask.save
        end
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
  
  def confirmed_teams
    Team.find(memberships.confirmed.map(&:team_id))
  end
  
  def fellow_team_members
    confirmed_teams.map(&:confirmed_members).flatten.uniq - [self]
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
