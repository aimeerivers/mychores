#!/usr/local/bin/ruby

require File.dirname(__FILE__) + '/../config/environment'
logger = RAILS_DEFAULT_LOGGER

dayindex = (Date.today).wday
nextweek = (1.weeks.from_now).at_beginning_of_day

numberdailyhtml = 0
numberdailyplain = 0
numberweeklyhtml = 0
numberweeklyplain = 0

@people = Person.find(:all, :conditions => ["usertype = 1"])
for person in @people
	unless person.email == '' or person.email.nil?
		unless person.notifications == "None"
		
			if person.notifications == "Daily"
			
				@workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due <= CURRENT_DATE and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC", person.id, person.id]
				
				unless @workload_tasks.empty?

					@number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < CURRENT_TIMESTAMP and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", person.id, person.id]
					
					if person.preference.html_emails == true
						Notifier::deliver_html_notification_email(person, @workload_tasks, @number_overdue)
						numberdailyhtml = numberdailyhtml + 1
					else
						Notifier::deliver_notification_email(person, @workload_tasks, @number_overdue)
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
			
				@workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and (next_due < ?) and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC", nextweek, person.id, person.id]
				
				unless @workload_tasks.empty?
					@number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due< CURRENT_TIMESTAMP and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", person.id]
					
					if person.preference.html_emails == true
						Notifier::deliver_html_weekly_email(person, @workload_tasks, @number_overdue)
						numberweeklyhtml = numberweeklyhtml + 1
					else
						Notifier::deliver_weekly_email(person, @workload_tasks, @number_overdue)
						numberweeklyplain = numberweeklyplain + 1
					end
					
				end	
				
			end
		end
	end
end


# Add an email on to the email queue table
# to send to myself after all others have been sent

@reportemail = Email.new
@reportemail.subject = "MyChores emails sent"
@reportemail.message = "The following emails were sent from MyChores:

Daily emails: " + numberdailyhtml.to_s + " rich text, and " + numberdailyplain.to_s + " plain text.
Weekly emails: " + numberweeklyhtml.to_s + " rich text, and " + numberweeklyplain.to_s + " plain text."

@reportemail.to = "clemex44@yahoo.co.uk"
@reportemail.save