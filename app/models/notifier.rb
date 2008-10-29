class Notifier < ActionMailer::Base

  helper :application
  
  def signup_thanks(person)
    # Email header info MUST be added here
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "Thanks for signing up with MyChores"
	
    # Email body substitutions go here
    @body["name"] = person.name
    @body["login"] = person.login
  end

  def signup_thanks_joined_team(person)
    # Email header info MUST be added here
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "Thanks for signing up with MyChores"
	
    # Email body substitutions go here
    @body["name"] = person.name
    @body["login"] = person.login
  end

  def contact_message(message)
    @recipients = "contact@mychores.co.uk"
    @from = message.email
    @subject = "Contact message: " + message.cat + " from " + message.name
		
    @body["name"] = message.name
    @body["email"] = message.email
    @body["cat"] = message.cat
    @body["content"] = message.content
  end
	
  def notification_email(person, workload, number_overdue, datetoday)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "Today's tasks from mychores.co.uk"
		
    @body["name"] = person.name
    @body["id"] = person.id
    @body["code"] = person.email_code
    @body["login"] = person.login
    @body["include_descriptions"] = person.preference.include_descriptions
		
    if person.preference.my_date_format == "%d/%m/%Y"
      @body["preferred_date_format"] = "%d %b %Y"
    elsif person.preference.my_date_format == "%m/%d/%Y"
      @body["preferred_date_format"] = "%b %d %Y"
    else
      @body["preferred_date_format"] = person.preference.my_date_format
    end
		
    @body["workload"] = workload
    @body["number_overdue"] = number_overdue
    @body["datetoday"] = datetoday
  end
	
  def html_notification_email(person, workload, number_overdue, datetoday)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "Today's tasks from mychores.co.uk"
		
    @body["name"] = person.name
    @body["id"] = person.id
    @body["code"] = person.email_code
    @body["login"] = person.login
    @body["include_descriptions"] = person.preference.include_descriptions
    @body["colourful_emails"] = person.preference.colourful_emails
		
    if person.preference.my_date_format == "%d/%m/%Y"
      @body["preferred_date_format"] = "%d %b %Y"
    elsif person.preference.my_date_format == "%m/%d/%Y"
      @body["preferred_date_format"] = "%b %d %Y"
    else
      @body["preferred_date_format"] = person.preference.my_date_format
    end
		
    @body["workload"] = workload
    @body["number_overdue"] = number_overdue
    @body["datetoday"] = datetoday
    content_type 'text/html'   #    <== note this line
  end
	
  def weekly_email(person, workload, number_overdue, datetoday)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "This week's tasks from mychores.co.uk"
		
    @body["name"] = person.name
    @body["id"] = person.id
    @body["code"] = person.email_code
    @body["login"] = person.login
    @body["include_descriptions"] = person.preference.include_descriptions
		
    if person.preference.my_date_format == "%d/%m/%Y"
      @body["preferred_date_format"] = "%d %b %Y"
    elsif person.preference.my_date_format == "%m/%d/%Y"
      @body["preferred_date_format"] = "%b %d %Y"
    else
      @body["preferred_date_format"] = person.preference.my_date_format
    end
		
    @body["workload"] = workload
    @body["number_overdue"] = number_overdue
    @body["datetoday"] = datetoday
  end
	
  def html_weekly_email(person, workload, number_overdue, datetoday)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "This week's tasks from mychores.co.uk"
		
    @body["name"] = person.name
    @body["id"] = person.id
    @body["code"] = person.email_code
    @body["login"] = person.login
    @body["include_descriptions"] = person.preference.include_descriptions
    @body["colourful_emails"] = person.preference.colourful_emails
		
    if person.preference.my_date_format == "%d/%m/%Y"
      @body["preferred_date_format"] = "%d %b %Y"
    elsif person.preference.my_date_format == "%m/%d/%Y"
      @body["preferred_date_format"] = "%b %d %Y"
    else
      @body["preferred_date_format"] = person.preference.my_date_format
    end
		
    @body["workload"] = workload
    @body["number_overdue"] = number_overdue
    @body["datetoday"] = datetoday
    content_type 'text/html'   #    <== note this line
  end
	
  def memrequest(team, person)
    @recipients = team.person.email # creator of the team
    @from = "contact@mychores.co.uk"
    @subject = "New membership request from mychores.co.uk"
		
    @body["name"] = team.person.name
    @body["team"] = team.name
    @body["person"] = person.name
    @body["login"] = person.login
  end
	
  def meminvite(team, person)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "New membership invitation from mychores.co.uk"
		
    @body["name"] = person.name
    @body["team"] = team.name
  end
	
  def password_reset_link(person)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "Password reset link from mychores.co.uk"
		
    @body["name"] = person.name
    @body["id"] = person.id
    @body["code"] = person.code
  end
	
  def signup_teaminvite(team, email, message, from_email)
    @recipients = email
    @from = from_email
    @subject = "Invitation to join a team at mychores.co.uk"
		
    @body["message"] = message
  end

  def newsletter(person, newsletter)
    @recipients = person.email
    @from = "contact@mychores.co.uk"
    @subject = "MyChores News: " + newsletter.title
		
    @body["name"] = person.name
    @body["content"] = newsletter.content
    @body["login"] = person.login
  end

  def outbound_email(email)
    @recipients = email.to
    @cc = email.cc
    @bcc = email.bcc
    @from = "contact@mychores.co.uk"
    @subject = email.subject
		
    @body["message"] = email.message
  end

end
