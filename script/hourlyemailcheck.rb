#!/usr/local/bin/ruby

require 'net/http'
require 'uri'

require File.dirname(__FILE__) + '/../config/environment'
logger = RAILS_DEFAULT_LOGGER



numberdailyhtml = 0
numberdailyplain = 0
numberweeklyhtml = 0
numberweeklyplain = 0

# Find those that want emails in this hour
@people = Person.find(:all, :joins => "LEFT JOIN preferences ON preferences.person_id = people.id", :conditions => ["HOUR(preferences.email_time_gmt) = HOUR(CONVERT_TZ(CURRENT_TIMESTAMP,'-6:00','+00:00'))"])

for temp_person in @people

  # Need to find the person again - because both Person and Preference contains an id
  # and it gets uber confused!!
	
  actual_person_id = temp_person.id
  person = Person.find(actual_person_id)

  unless person.email == '' or person.email.nil?
    unless person.notifications == "None" or person.email_verified == false
		
      puts person.login
		
      # work out all details for this person's timezone
      @mytimezone = TimeZone.new(person.timezone_name)
      @datetoday = Date.parse(@mytimezone.today().to_s)
      dayindex = (@datetoday).wday
      nextweek = @datetoday + 7
		
      if person.notifications == "Daily"
			
        @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due <= ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @datetoday, person.id, person.id]
				
        unless @workload_tasks.empty?

          @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, person.id, person.id]
					
          # puts "Sending daily email to " + person.name + " (" + person.email + ")"
					
          if person.preference.html_emails == true
            Notifier::deliver_html_notification_email(person, @workload_tasks, @number_overdue, @datetoday)
            numberdailyhtml = numberdailyhtml + 1
          else
            Notifier::deliver_notification_email(person, @workload_tasks, @number_overdue, @datetoday)
            numberdailyplain = numberdailyplain + 1
          end
				
        end		
				
      elsif (person.notifications == "Sundays" && dayindex == 0) \
          || (person.notifications == "Mondays" && dayindex == 1) \
          || (person.notifications == "Tuesdays" && dayindex == 2) \
          || (person.notifications == "Wednesdays" && dayindex == 3) \
          || (person.notifications == "Thursdays" && dayindex == 4) \
          || (person.notifications == "Fridays" && dayindex == 5) \
          || (person.notifications == "Saturdays" && dayindex == 6)
			
        @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and (next_due < ?) and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", nextweek, person.id, person.id]
				
        unless @workload_tasks.empty?
          @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due< CONVERT_TZ(CURRENT_TIMESTAMP,'-6:00','+00:00') and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", person.id]
					
          # puts "Sending weekly email to " + person.name + " (" + person.email + ")"
					
          if person.preference.html_emails == true
            Notifier::deliver_html_weekly_email(person, @workload_tasks, @number_overdue, @datetoday)
            numberweeklyhtml = numberweeklyhtml + 1
          else
            Notifier::deliver_weekly_email(person, @workload_tasks, @number_overdue, @datetoday)
            numberweeklyplain = numberweeklyplain + 1
          end
					
        end	
				
      end
    end
  end
end















###############################################################

# Now for the Twitter notifications!
# 
# API Documentation
# http://groups.google.com/group/twitter-development-talk/web/api-documentation


# Find those that want twitter notifications in this hour
@people = Person.find(:all, :joins => "LEFT JOIN preferences ON preferences.person_id = people.id", :conditions => ["HOUR(preferences.twitter_receive_time_gmt) = HOUR(CONVERT_TZ(CURRENT_TIMESTAMP,'-6:00','+00:00')) and preferences.twitter_receive = true"])

for temp_person in @people

  # Need to find the person again - because both Person and Preference contains an id
  # and it gets uber confused!!
	
  actual_person_id = temp_person.id
  person = Person.find(actual_person_id)
		
  # work out details for this person's timezone
  @mytimezone = TimeZone.new(person.timezone_name)
  @datetoday = Date.parse(@mytimezone.today().to_s)
	
  @todays_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by list_id ASC, name ASC", @datetoday, person.id, person.id]
	
  if @todays_tasks.empty?
    twitter_notify_string = "No tasks due today. This message does not report overdue tasks."
  else
    twitter_notify_string = ""
    current_list = ""
		
    for task in @todays_tasks
		
      if task.list.name != current_list
        unless current_list == ""
          # Unless it's the start of the whole message, add a full stop.
          twitter_notify_string += ". " # To end the previous list.
        end
				
        current_list = task.list.name
        twitter_notify_string += current_list + ": " # Add the new list name
        twitter_notify_string += task.short_name # Add the task
      else
        twitter_notify_string += "; " + task.short_name # Add the task as one of a list
      end
			
    end
    twitter_notify_string += "." # Add a final full stop at the end.
  end
	
  # Chop to maximum 140 characters
  updatelength = twitter_notify_string.length
  chopped = false
  while updatelength > 137
    twitter_notify_string.chop!
    chopped = true
    updatelength = twitter_notify_string.length
  end
	
  if chopped == true
    twitter_notify_string += '...' # to indicate that it's been chopped.
  end
	
	
	
	
  begin
    url = URI.parse('http://twitter.com/direct_messages/new.xml')
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth Setting.value('twitter_username'), Setting.value('twitter_password')
    req.set_form_data({'text' => twitter_notify_string, 'user' => person.preference.twitter_email})
	
    begin
      res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
	
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        if res.body.empty?
          # Twitter is not responding properly
          @reportemail = Email.new
          @reportemail.subject = "Twitter is not responding properly"
          @reportemail.message = "A Twitter notification to " + person.login + " failed to send."
          @reportemail.to = "clemex44@yahoo.co.uk"
          @reportemail.save
        else
          # Twitter update succeeded
          # puts res.body
        end
	
      else
        # Twitter update failed for an unknown reason
        res.error!
        @reportemail = Email.new
        @reportemail.subject = "Twitter failed for an unknown reason"
        @reportemail.message = "A Twitter notification to " + person.login + " failed to send."
        @reportemail.to = "clemex44@yahoo.co.uk"
        @reportemail.save
      end
	
    rescue
      # Twitter update failed - check username/password
      @reportemail = Email.new
      @reportemail.subject = "Twitter notification failed - check username/password"
      @reportemail.message = "A Twitter notification to " + person.login + " failed to send."
      @reportemail.to = "clemex44@yahoo.co.uk"
      @reportemail.save
    end
	
  rescue SocketError
    # Twitter is currently unavailable
    @reportemail = Email.new
    @reportemail.subject = "Twitter is not responding"
    @reportemail.message = "A Twitter notification to " + person.login + " failed to send."
    @reportemail.to = "clemex44@yahoo.co.uk"
    @reportemail.save
  end
	
  sleep(5) # Give poor Twitter a few seconds breathing space!
	
end















###############################################################

# Now deal with escalations


# Find anyone who's just gone past midnight
# This is the craziest complicated thing - especially with USA going to summer time at different times from Europe!
# I am going to try assuming that America is always 5 hours behind GMT.
# This may make the escalations happen at 00:00, 01:00 or 02:00
# All of which should be okay. The problem was if they ended up happening at 23:00 the previous day.
@people = Person.find(:all, :conditions => ["HOUR(midnight_gmt) = HOUR(CONVERT_TZ(CURRENT_TIMESTAMP,'-5:00','+00:00'))"])

for person in @people

  # work out all details for this person's timezone
  @mytimezone = TimeZone.new(person.timezone_name)
  @datetoday = Date.parse(@mytimezone.today().to_s)
  dayindex = (@datetoday).wday
  nextweek = @datetoday + 7

  # Find that person's tasks which have just passed their escalation date
  # Note this may get skewy if a team contains people from multiple time zones!
  @escalated_tasks = Task.find_by_sql ["select * from tasks where status='active' and escalation_date <= ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, person.id, person.id]
	
  for task in @escalated_tasks
    escalation_actions = task.task_missed_options
		
    while task.escalation_date <= @datetoday
      # Increase its importance?
      if escalation_actions.include?("increase_importance")
        if task.current_importance < 7
          task.current_importance += 1
        end
      end
			
      # Re-schedule it?
      if escalation_actions.include?("reschedule")
        # Re-schedule based on the date it should have been done.
        # This includes re-setting the escalation date.
        task.reschedule(task.next_due)
      else
			
        # If not re-scheduled, still need to push escalation date forward for next time.
        if task.recurrence_measure == 'days'
          # easy - just count on the number of days
          task.escalation_date += task.recurrence_interval.to_i
					
        elsif task.recurrence_measure == 'weeks'
          task.escalation_date += ((task.recurrence_interval.to_i) * 7)
					
        elsif task.recurrence_measure == 'months'
          # Add 30 days for each month to skip
          task.escalation_date += ((task.recurrence_interval.to_i) * 30)
        end
					
      end
			
    end
		
    # After all that remember to save the task!
    task.save
		
  end
end
