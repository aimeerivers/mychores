class AdminController < ApplicationController

  before_filter :login_required, :except => [:login, :register, :logout, :forgotpassword, :resetpassword, :verify_email, :subscription_options]

  def login
    case request.method
    when :post
      if session[:person] = Person.authenticate(params[:person][:login], params[:person][:password])
      
      	# Load up their preferences too
      	session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      	
      	# The short date format is like 23/02/2008 - what is stored in the database.
      	session[:preferred_short_date_format] = session[:preference].my_date_format
      
        # Also store the long format - ie 23 Feb 2008.
        if session[:preference].my_date_format == "%d/%m/%Y"
          session[:preferred_long_date_format] = "%d %b %Y"
        elsif session[:preference].my_date_format == "%m/%d/%Y"
          session[:preferred_long_date_format] = "%b %d %Y"
        else
          session[:preferred_long_date_format] = session[:preference].my_date_format
        end
      	
        flash[:notice]  = "You are now logged in."
        redirect_back_or_default :controller => 'home', :action => 'index'
      else
        flash[:notice]  = "Login failed - please try again."
        @login = params[:person_login]
      end
    end
  end
  
  
  def register
    @person = Person.new(params[:person])
    session[:referrer] = params[:referrer] if params[:referrer]
    session[:code] = params[:code] if params[:code]
		
    unless session[:code].nil?
      @invitation = Invitation.find(:first, :conditions => [ "code = ? and accepted = 0", session[:code] ])
      unless @invitation.nil?
        session[:email] = @invitation.email
        session[:referrer] = @invitation.person.login
      end
    end
		

    if request.post? && recaptcha_valid?(params, @person) && @person.save

      session[:person] = @person
    
      # Create them a preferences record
      preference = Preference.new
      preference.person_id = @person.id
      
      # Sort out their date format
      if TimeZone.us_zones.to_s.include?(@person.timezone_name) || @person.timezone_name.include?("America")
        preference.my_date_format = "%m/%d/%Y"
        session[:preferred_short_date_format] = "%m/%d/%Y"
        session[:preferred_long_date_format] = "%b %d %Y"
        preference.language_code = "en-US"
      else
        preference.my_date_format = "%d/%m/%Y"
        session[:preferred_short_date_format] = "%d/%m/%Y"
        session[:preferred_long_date_format] = "%d %b %Y"
        preference.language_code = "en"
      end
      
      preference.save
      session[:preference] = preference
        
      
      auto = @person.signup_new_user(session[:code])
      # Includes creating standard tasks and sending emails
      
      
      # Double-check the password is saved correctly
      Person.updatepassword(@person, params[:person][:password])
      
      if auto == 1
        redirect_to :controller => 'admin', :action => 'welcome', :auto => 1
      else
        redirect_to :controller => 'admin', :action => 'welcome'
      end
      
    end      
  end  
  
  
  
  
  
  
  
  
  def logout
    session[:person] = nil
    session[:preference] = nil
    session[:preferred_short_date_format] = "%d/%m/%Y"
    session[:preferred_long_date_format] = "%d %b %Y"
    flash[:notice]  = "You are now logged out."
    redirect_to :controller => 'home', :action => 'index'
  end

  def changepassword
    @person = Person.find(session[:person].id)
    case request.method
    when :post
      if Person.authenticate(@person.login, params[:person_current_password])
        if params[:person_new_password] == params[:person_confirm_new_password]
          if params[:person_new_password].length > 4
            # Save the password
            Person.updatepassword(@person, params[:person_new_password])
		      		
            flash[:notice] = "Password changed successfully."
            redirect_back_or_default :controller => 'people', :action => 'show_by_login', :login => @person.login
          else
            flash[:notice] = "New password must be at least 5 characters."
          end
        else
          flash[:notice] = "New password did not match the confirmation."
        end
      else
        flash[:notice]  = "Current password entered incorrectly."
        # @login = params[:person_login]
      end
    end
  end
  
	
  def resetpassword
    # This is the page from an email link if someone has forgotten their password.
    # Obviously no checking for correct password; checking for correct code instead.
    @valid_request = 0
    @person = Person.find(session[:person].id)
    @code = params[:code]
		
    if @person.nil?
      @valid_request = 0
		
    elsif @person.code == @code
      @valid_request = 1
		
      case request.method
      when :post
        if params[:person_new_password] == params[:person_confirm_new_password]
          if params[:person_new_password].length > 4
            # Save the password
            Person.updatepassword(@person, params[:person_new_password])
						
            # Make sure they are definitely logged out!
            session[:person] = nil
						
            # Go back to the welcome page
            flash[:notice] = "Password changed successfully. You may now login with the new password."
            redirect_back_or_default :controller => 'home', :action => 'welcome'
						
          else
            flash[:notice] = "New password must be at least 5 characters."
          end
        else
          flash[:notice] = "New password did not match the confirmation."
        end
      end
    else
      # Request is not valid - eg, wrong code.
    end
  end
  
  def forgotpassword
    @person = session[:person]
    case request.method
    when :post
      if params[:login_or_email].empty?
        flash[:notice] = "If you are having trouble, email contact@mychores.co.uk for help."
				
      else
        searchstring = params[:login_or_email]
        @persontoemail = Person.find(:first, :conditions => [ "login = ? or email = ?", searchstring, searchstring])
				
        if @persontoemail.nil?
          flash[:notice] = "Login or email not found."
					
        else
          # There is a match.
					
          # Redirect
          flash[:notice] = "An email will shortly be sent to you with further instructions to change your password."
          redirect_back_or_default :controller => 'home', :action => 'welcome'
					
          # Send an email
          @email = Email.new
          @email.subject = "Password reset link from MyChores"
          @email.message = "Dear #{@persontoemail.name},

The link below will enable you to change your MyChores password. If you do not want to change your password please ignore this email and your password will remain the same.

To change your password, click here:

http://www.mychores.co.uk/admin/resetpassword/#{@persontoemail.id}?code=#{@persontoemail.code}

Your login ID is: #{@persontoemail.login}

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
          @email.to = @persontoemail.email
          @email.save
          # Notifier::deliver_password_reset_link(@persontoemail)
        end
      end
    end
  end
    
  def welcome
    @person = session[:person]
		
    if params[:auto]
      @auto_team_added = true
      @teams = Team.find(:all, :conditions => [ "id in (select team_id from memberships where person_id = ?)", @person.id ])
    else
      @auto_team_added = false
      @team = Team.find(:first, :conditions => [ "id in (select team_id from memberships where person_id = ?)", @person.id ])
    end
  end
	
	
	
  def help
    @person = Person.find(session[:person].id)
  end
	
	

  def preferences
    # Reload session
    # Shouldn't have to do this but for some reason we do.
	    
    session[:person] = Person.find(session[:person].id)
    @person = session[:person]
    
    @mytimezone = TimeZone.new(@person.timezone_name)
    @datetoday = Date.parse(@mytimezone.today().to_s)
    
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
		
    @importances = Importance.find(:all, :order=>"value desc")
		
    @temp_edit_options = @preference.quick_edit_options
		
  end
	
	
	
	
  def changepreferences
    @person = Person.find(session[:person].id)
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
	
  
    if @person.update_attributes(params[:person])
    	
      @preference.update_attributes(params[:preference])
			
      # update the session variables
      session[:person] = @person
      session[:preference] = @preference
      
      @preference.quick_edit_options = params[:quick_edit_options]
      
      @preference.workload_columns = params[:workload_columns]

      if @preference.workload_columns.nil?
        # Avoid an error if they unticked everything
        @preference.workload_columns = "Taskonly, Done"
        # Done is the only column which is always included
        # And they should at least have the task if nothing else.
      end
    		
      unless @preference.workload_columns.include?("Taskonly") or @preference.workload_columns.include?("Listtask")
        # Make sure they at least have a task showing!
        @preference.workload_columns.insert(0,"Taskonly")
      end
        
        
        
      # Template occur on days
      if params[:occur_on]
        @preference.template_recurrence_occur_on = params[:occur_on]
      else
        # If no days ticked assume all.
        @preference.template_recurrence_occur_on = "0,1,2,3,4,5,6"
      end
	 	
    	
      # Template escalation options
      if params[:template_task_missed_options]
        @preference.template_task_missed_options = params[:template_task_missed_options]
      else
        # It is possible that they don't want anything to happen.
        @preference.template_task_missed_options = ""
      end
	 	
    	
      # In-place editing
      if params[:quick_edit_options]
        @preference.quick_edit_options = params[:quick_edit_options]
      else
        # Save an empty string to avoid getting errors when doing include?()
        @preference.quick_edit_options = ""
      end
      
    	
      # When all options configured, save the preferences	
      @preference.save
      
      
      
      # The short date format is like 23/02/2008 - what is stored in the database.
      session[:preferred_short_date_format] = session[:preference].my_date_format
    
      # Also store the long format - ie 23 Feb 2008.
      if session[:preference].my_date_format == "%d/%m/%Y"
        session[:preferred_long_date_format] = "%d %b %Y"
      elsif session[:preference].my_date_format == "%m/%d/%Y"
        session[:preferred_long_date_format] = "%b %d %Y"
      else
        session[:preferred_long_date_format] = session[:preference].my_date_format
      end
		
		
      flash[:notice] = "Preferences saved."
      redirect_to :action => 'preferences'
			
    else
      flash[:notice] = "Sorry, there was a problem updating your preferences."
      @importances = Importance.find(:all, :order=>"value desc")
      render :action => 'preferences'
    end
		
	
  end
	
	

  def email
    # Reload session
    # Shouldn't have to do this but for some reason we do.
	    
    session[:person] = Person.find(session[:person].id)
    @person = session[:person]
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
  end
	
	
  def changeemail
    @person = Person.find(session[:person].id)
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
	
    # Check if their email address has changed
    if params[:person][:email] != @person.email
      @email_changed = true
    else
      @email_changed = false
    end
    
    if @person.update_attributes(params[:person])
    	
      @preference.update_attributes(params[:preference])
        
        
      # See if we need to prompt to verify the email address
      if @email_changed == true
        @person.email_code = Person.sha1(@person.email + Time.now.to_s)
        @person.email_verified = false
        @person.save
          
        # Send an email
        @email = Email.new
        @email.subject = "Please verify your new email address for MyChores"
        @email.message = "Hi " + @person.name + ",
      
MyChores has noticed that you changed your email address. Please verify by clicking the link below so that you can receive notifications and newlsetters to this email address.
      
Click here to verify:
http://www.mychores.co.uk/admin/verify_email/" + @person.id.to_s + "?code=" + @person.email_code + "
      
      
If you have any problems please email contact@mychores.co.uk
      
http://www.mychores.co.uk"
        @email.to = @person.email
        @email.save
          
      end
    		
      @preference.save
      flash[:notice] = "Email settings successfully updated."
      redirect_to :action => 'help'
        
    else
      render :action => 'email'
    end
  end
	
	

  def theme
    # Reload session
    # Shouldn't have to do this but for some reason we do.
	    
    session[:person] = Person.find(session[:person].id)
    @person = session[:person]
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
  end
	
	
  def changetheme
    @person = Person.find(session[:person].id)
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
	
    if @preference.update_attributes(params[:preference])
      session[:preference] = @preference
      flash[:notice] = "Theme successfully changed."
      redirect_to :action => 'help'
        
    else
      render :action => 'theme'
    end
  end
	
	
	
	
	
	
	
	
	

  def flickr
    # Reload session
    # Shouldn't have to do this but for some reason we do.
	    
    session[:person] = Person.find(session[:person].id)
    @person = session[:person]
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
		
    if @preference.flickr_email.nil?
      @preference.flickr_email = @person.email
    end
  end
	
	
	
	

  def twitter
    # Reload session
    # Shouldn't have to do this but for some reason we do.
	    
    session[:person] = Person.find(session[:person].id)
    @person = session[:person]
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
  end
	
	
	
	
  def changetwitter
    @person = Person.find(session[:person].id)
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
		
		
    case request.method
    when :post
      
      if @preference.update_attributes(params[:preference])
      	
        @preference.twitter_lists = params[:include_lists]
      	
        # Save the password
        Preference.updatepassword(@preference, params[:twitter_password])
	      	
        flash[:notice] = "Twitter Integration settings updated."
			
        # update the session variables
        session[:person] = @person
        session[:preference] = @preference
        @preference.save
			
        redirect_to :action => 'help'
				
				
      else
        render :action => 'twitter'
      end
		
    end
		
  end
	
	


  def twittertest
  
    require 'net/http'
    require 'uri'
  
    twitter_username = params[:twitter_username]
    twitter_password = params[:twitter_password]
    result = 0
  
    begin
	
      url = URI.parse('http://twitter.com/account/verify_credentials.xml')
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth twitter_username, twitter_password
		
      begin
        res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
			
        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          # OK
          if res.body.empty?
            # Uh oh, Twitter had an error
            result = -1
          else
            # Sucess!
            result = 1
					
					
					
            # Now we want to add them to the MyChores friends list
            url2 = URI.parse('http://twitter.com/friendships/create/' + twitter_username + '.xml')
            req2 = Net::HTTP::Post.new(url2.path)
            req2.basic_auth Setting.value('twitter_username'), Setting.value('twitter_password')
					
            begin
              res2 = Net::HTTP.new(url2.host, url2.port).start {|http2| http2.request(req2) }
            rescue
              res2.error!
            end
					
					
					
          end
        else
          # Twitter had an error
          res.error!
          result = -1
        end
			
      rescue
        # Wrong password
        result = 0
      end
		
		
	
    rescue SocketError
      # Twitter is currently unavailable
      result = -1
    end
	
    if result == 1
      # Success
      render :text => "<img src='/images/tick.png' width='12' height='12' alt='' /> <span style='color:green;'>Twitter authentication succeeded</span>"
      
    elsif result == 0
      # Wrong password
      render :text => "<img src='/images/redx.png' width='15' height='10' alt='' /> <span style='color:red;'>Twitter authentication failed</span>"
      
    else
      # Twitter had an error
      render :text => "<img src='/images/redx.png' width='15' height='10' alt='' /> <span style='color:red;'>Something went wrong with Twitter</span>"
    end
    
  end	
	
	

  def changelogin
    @person = Person.find(session[:person].id)
  end
	
	
  def changeloginid
    @person = Person.find(session[:person].id)
    return if @person.status.blank?
    @person.login = params[:person][:login]
    if @person.save
      flash[:notice] = "Login changed successfully"
      session[:person] = @person
      redirect_to :controller => 'people', :action => 'show_by_login', :login => @person.login
    else
      render :action => 'changelogin'
    end
  end
	
	
	
  def ss_check
	
    @supporters = Preference.find(:all, :order => ["updated_on DESC"], :conditions => ["twitter_email != ''"] )
		
    @promoters = Person.find_by_sql(["select parent.login, parent.name, parent.status, parent.usertype, count(child.id) as referred from people child, people parent where child.parent_id = parent.id AND child.usertype = 1 group by parent.name having referred > 4"])
	
  end
	
	
	
  def openid_check
	
    @people = Person.find(:all, :order => ["updated_on DESC"], :conditions => ["openid_url != ''"] )
		
  end
	


  def email_verify
    # Send a link in an email
    # Return wherever we came from
    
    @person = Person.find(session[:person].id)
    
    # Generate a new email code
    @person.email_code = Person.sha1(@person.email + Time.now.to_s)
    @person.email_verified = false
    @person.save
    
    # Create the email    
    @email = Email.new
    @email.subject = "Please verify your email address for MyChores"
    @email.message = "Hi " + @person.name + ",

This link will enable you to verify your email address with MyChores. Once your email address has been verified you will be able to receive notifications and newsletters.

Click here to verify:
http://www.mychores.co.uk/admin/verify_email/" + @person.id.to_s + "?code=" + @person.email_code + "


If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
    @email.to = @person.email
    @email.save
    
    
    # Flash information
    flash[:notice]  = "You will soon be sent an email with a link to verify your email address."
    
    
    redirect_to :action => 'email'
  end
  
  
  
  def verify_email
    # Look up user based on id and email code.
    # If matched, email is verified.
    
    @is_valid = false
    
    if params[:id] and params[:code]
      @person = Person.find(:first, :conditions => [ "id = ? and email_code = ?", params[:id], params[:code] ])
      if @person.nil?
        @is_valid = false
      else
        # Hooray! They are validated
        @person.email_verified = true
        @person.save
        @is_valid = true
      end
    else
      @is_valid = false
    end
  end
  
  
  
  def subscription_options
    # Look up user based on id and email code.
    # This allows people to change their email settings without being logged in.
    # It also serves to validate their email address.
    
    @is_valid = false
    
    if params[:id] and params[:code]
      @id = params[:id]
      @code = params[:code]
      
      @person = Person.find(:first, :conditions => [ "id = ? and email_code = ?", @id, @code ])
      if @person.nil?
        @is_valid = false
      else
        # Allow them in.
        @is_valid = true
        key = params[:key]
        value = params[:value]
        
        if key == 'email'
          if value == 'off'
            @person.notifications = 'None'
          elsif value == 'on'
            @person.notifications = 'Daily'
          end
        elsif key == 'newsletter'
          if value == 'off'
            @person.newsletters = false
          elsif value == 'on'
            @person.newsletters = true
          end
        end
        
        @person.email_verified = true
        @person.save
        
      end
    else
      @is_valid = false
    end
  end
  
  
  
  def unregister
    @person = session[:person]
  end
  
  
  def unregister_do
  
    @person = session[:person]
  
    # Send an email
    @email = Email.new
    @email.subject = @person.login + " has left MyChores"
    unless params[:message].empty?
      @email.message = params[:message]
    else
      @email.message = "No message was left."
    end
    @email.to = "contact@mychores.co.uk"
    @email.save
    
    
    # Find all tasks assigned to this person
    @tasks = Task.find(:all, :conditions => ["person_id = ?", @person.id])
    
    # Assign them all to the team and turn off task rotating.
    for task in @tasks
      task.person_id = nil
      task.rotate = 0
      task.save
    end
    
    # Edit their preferences
    @preference = @person.preference
    @preference.twitter_receive = false
    @preference.twitter_post = false
    @preference.save
    
    # Edit this person
    @person.login = Person.sha1(@person.login + Time.now.to_s) # So that they could sign up again if they wanted
    @person.email = "deleted@mychores.co.uk"
    @person.email_verified = false
    @person.notifications = "None"
    @person.newsletters = false
    @person.openid_url = nil
    @person.usertype = 3
    @person.save
    
    
    # Clear the session to log them out
    session[:person] = nil
    session[:preference] = nil
    
    flash[:notice]  = "Thank you for using MyChores. Goodbye."
    redirect_to :controller => 'home', :action => 'index'
    
  end
  
  
  protected
  
  def recaptcha_valid?(params, person)
    return true if %w(development test).include?(RAILS_ENV)
    validate_recap(params, person.errors)
  end
	
end
