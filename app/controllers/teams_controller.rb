class TeamsController < ApplicationController

  before_filter :login_required, :except => [:show, :rss, :icalendar]
  
  def index
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def list
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def show
    @team = Team.find(params[:id])
    @memberships = @team.memberships
    @invitations = Invitation.find(:all, :conditions => [ "team_id = ? and accepted = 0" , @team.id ])
    @lists = List.find(:all, :conditions => [ "team_id = ?", @team.id ], :order => "name ASC")
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(params[:team])
    @person = session[:person]
    @team.person_id = @person.id # created by
    if @team.save
      validitykey = Person.sha1(@person.name + Time.now.to_s)
      @membership = Membership.new(:team_id => @team.id, :person_id => session[:person].id, :confirmed => 1, :validity_key => validitykey)
      @membership.save
      redirect_to :action => 'show', :id => @team.id
    else
      render :action => 'new'
    end
  end

  def edit
    @team = Team.find(params[:id])
  end

  def update
    @team = Team.find(params[:id])
    if @team.update_attributes(params[:team])
      redirect_to :action => 'show', :id => @team
    else
      render :action => 'edit'
    end
  end

  def destroy
    @team = Team.find(params[:id])
    if @team.person_id == session[:person].id
	 	  
      @team.memberships.each do |membership|
        membership.destroy
      end
	 	  
      @team.destroy
	 	  
	 	  
	 	  
      flash[:notice] = "Your team was deleted successfully."
    else
      flash[:notice] = "Team not deleted. You can only delete teams which you created."
    end
	 
    redirect_to :controller => 'tasks', :action => 'workload'
  end
  
  
  
  def invite
    @team = Team.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = ?", session[:person].id, @team.id]
    if @check.empty?
      flash[:notice] = "You cannot invite someone to join this team because you are not a member of it yourself."
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id
    else
      @person = session[:person]
    end
  end
  
  
  
  def invitesend
    @team = Team.find(params[:id])
		
    if params[:email].empty?
      flash[:notice] = "You didn't enter an email address."
      redirect_to :controller => 'teams', :action => 'invite', :id => @team.id
    else
		
      # Are they allowed to invite someone into this team?
      @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = ?", session[:person].id, @team.id]
      if @check.empty?
        flash[:notice] = "You cannot invite someone to join this team because you are not a member of it yourself."
        redirect_to :controller => 'teams', :action => 'show', :id => @team.id
				
      else
        # Is the person they invited already registered with MyChores?
        @personinvited = Person.find(:first, :conditions => [ "email = ?", params[:email] ])
        if @personinvited.nil?
				
          # Just check that they haven't been invited before ...
          @invitedbefore = Invitation.find(:first, :conditions => [ "email = ? and team_id = ?", params[:email], @team.id] )
					
          if @invitedbefore.nil?
            # Send the email
            # Notifier::deliver_signup_teaminvite(@team, params[:email], params[:message], session[:person].email)
						
            # Add into invitations table
            @invitation = Invitation.new(
              :person_id => session[:person].id,
              :team_id => @team.id,
              :email => params[:email],
              :code => Person.sha1(params[:email] + Time.now.to_s),
              :accepted => false)
            @invitation.save
						
            # Send an email
            @email = Email.new
            @email.subject = "Invitation to join a team at mychores.co.uk"
            @email.message = params[:message] + "

Please use the following link to sign up and join the team:
http://www.mychores.co.uk/admin/register?code=" + @invitation.code
				      
            @email.to = params[:email]
            @email.save
						
            flash[:notice] = "An invitation will shortly be sent inviting " + params[:email] + " to join this team."
						
          else
            flash[:notice] = params[:email] + " has already been invited to join " + @team.name + "."
          end
					
        else
          # The email address they entered belongs to someone already registered on MyChores
          # Are they already in the team?
          @alreadyinteam = Membership.find(:first, :conditions => [ "team_id = ? and person_id = ?", @team.id, @personinvited.id ])
					
          if @alreadyinteam.nil?
            # Make a membership record
            validitykey = Person.sha1(@personinvited.name + Time.now.to_s)
            @membership = Membership.new(:team_id => @team.id, :person_id => @personinvited.id, :invited => 1, :confirmed => 0, :validity_key => validitykey)
            @membership.save
					
            # Send the invitee the standard email to invite them into a team
            # Notifier::deliver_meminvite(@team, @personinvited)
						
						
            # Send an email
            @email = Email.new
            @email.subject = "New membership invitation from mychores.co.uk"
            @email.message = "Dear " + @personinvited.name + ",

You have been invited to join a team: " + @team.name + ".

Login to MyChores to accept or decline this invitation. You'll find the links when you login.

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
            @email.to = @personinvited.email
            @email.save
						
						
            flash[:notice] = @personinvited.name + " is already registered on MyChores. An invitation will be sent inviting " + @personinvited.name + " to join " + @team.name + "."
						
          else
            # They are already a member of the team!
            flash[:notice] = @personinvited.name + " is already a member, or has already been invited to join " + @team.name + "."
          end
					
        end
      end
			
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id
    end
  end
	
	
	
	
  
  
  
  def add_virtual
    @team = Team.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = ?", session[:person].id, @team.id]
    if @check.empty?
      flash[:notice] = "You cannot invite someone to join this team because you are not a member of it yourself."
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id
    else
      @person = session[:person]
			
      unless params[:name].nil? or params[:name].empty?
        name = params[:name]
			   
        # Create the virtual person record
        @virtualmember = Person.new(:name => name, :usertype => 2, :email => 'virtual@mychores.co.uk', :login => Person.sha1(name + Time.now.to_s), :password => Person.sha1(name.reverse + Time.now.to_s), :password_confirmation => Person.sha1(name.reverse + Time.now.to_s), :timezone_name => @person.timezone_name, :parent_id => @person.id)
        if @virtualmember.save
			   
          # Create the preference (for consistency and in case they ever convert to a real member)
          @virtualpreference = Preference.new(:person_id => @virtualmember.id)
          @virtualpreference.save
                 
          # Join to the team
          @membership = Membership.new(:person_id => @virtualmember.id, :team_id => @team.id, :confirmed => true)
          @membership.save
               
          flash[:notice] = "Virtual team member successfully added."
          redirect_to :controller => 'teams', :action => 'show', :id => @team.id
               
        else
               
          flash[:notice] = "Virtual team member could not be added."
          redirect_to :controller => 'teams', :action => 'add_virtual', :id => @team.id
               
        end
      end
    end
  end
	
	
	
	
  
  
  
  def add_kids
    @team = Team.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = ?", session[:person].id, @team.id]
    if @check.empty?
      flash[:notice] = "You cannot invite someone to join this team because you are not a member of it yourself."
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id
    else
      @person = session[:person]
      
			
      unless params[:name].nil? or params[:name].empty?
			
        for name in params[:name]
        
          # First see if there is already a kid with that name in this person's teams.
          # If so, chances are it's the same person!
          
          @kidcheck = Person.find_by_sql ["select * from people where usertype = 4 and name = ? and id in (select person_id from memberships where confirmed = 1 and  team_id in (select team_id from memberships where confirmed = 1 and person_id = ?)) order by name ASC", name, session[:person].id]
          unless @kidcheck.empty?
            @kid = @kidcheck[0]
            
            # Join that kid to the team
            # But wait! Just make sure that they aren't already!
            
            @membership = Membership.find(:first, :conditions => ["person_id = ? and team_id = ?", @kid.id, @team.id])
            unless @membership.nil?
              # Just ensure that the membership is confirmed.
              @membership.confirmed = true
              @membership.save
              
            else
              # Okay, create the membership.
              @membership = Membership.new(:person_id => @kid.id, :team_id => @team.id, :confirmed => true)
              @membership.save
            end
            
          else
            # need to create a new kid record
			   
            # Create a record for the kid (usertype 4)
            @kid = Person.new(:name => name, :usertype => 4, :email => 'kids@mychores.co.uk', :default_view => "Collage", :login => Person.sha1(name + Time.now.to_s), :password => Person.sha1(name.reverse + Time.now.to_s), :password_confirmation => Person.sha1(name.reverse + Time.now.to_s), :timezone_name => @person.timezone_name, :parent_id => @person.id)
            if @kid.save
    			   
              # Create the preference (if they convert to a full member these are the preferences they might want)
              @virtualpreference = Preference.new(:person_id => @kid.id, :workload_display => "Only today's tasks", :workload_columns => "Listonly, Taskonly", :my_date_format => @person.preference.my_date_format)
              @virtualpreference.save
                       
              # Join to the team
              @membership = Membership.new(:person_id => @kid.id, :team_id => @team.id, :confirmed => true)
              @membership.save
    
            end
            
          end
              
        end
        
        flash[:notice] = "Kid(s) added to your team."
        redirect_to :controller => 'teams', :action => 'show', :id => @team.id
               
      end
      
    end
  end
	
	
	
	
	
	
  #	def updateall
  # useful for adding in some controlled fields, eg the  code.
  # should not be available all the time.
  #		@teams = Team.find(:all)
  #		for team in @teams
  #			team.save
  #		end
  #	end
	
	
	
  def rss
    @team = Team.find_by_code(params[:id])
    @completions = Completion.find_by_sql ["select * from completions where date_completed >= DATE_SUB(CURDATE(),INTERVAL 7 DAY) and task_id in (select id from tasks where list_id in (select id from lists where team_id = ?)) order by date_completed desc, created_on desc", @team.id]
    render(:layout => false, :content_type => 'application/rss+xml')
  end
	
	
	
  def icalendar
    require 'icalendar'
    # include 'Icalendar'
	    
    @team = Team.find_by_code(params[:id])
    @teamtasks = Task.find_by_sql ["select * from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id = ?)) order by next_due ASC, list_id ASC, name ASC", @team.id]
		
		
    unless params[:type].nil?
      objecttype = params[:type]
    else
      objecttype = "todo"
    end
		
		
    @ical = Icalendar::Calendar.new
		
    for task in @teamtasks
		
		
      # Could either be an event or a todo
      if objecttype == "event"
        todo = Icalendar::Event.new
        todo.dtstart = Date.parse(task.next_due.to_s)
      else
        todo = Icalendar::Todo.new
        todo.due = Date.parse(task.next_due.to_s)
      end
		  
		  
      todo.summary = task.list.name + ": " + task.name
		  
      todo.url = URI.parse("http://www.mychores.co.uk/tasks/show/" + task.id.to_s)
      todo.status = "NEEDS-ACTION"
		  
      if task.description.empty?
        todo.description = "This task has no description."
      else
        todo.description = task.description.dump
      end
		  
      todo.add_category(task.list.name)
		  
      # Recurrence
      unless task.one_off == true
        if task.recurrence_measure == 'days'
          frequency = 'DAILY'
        elsif task.recurrence_measure == 'weeks'
          frequency = 'WEEKLY'
        elsif task.recurrence_measure == 'months'
          frequency = 'MONTHLY'
        end
        # todo.add_recurrence_rule("FREQ=" + frequency + ";INTERVAL=" + task.recurrence_interval.to_s)
      end
		  
      # Priority
      # Let's take MyChores importance, inverted, to iCalendar priority.
		  
      todo.priority = task.current_importance
		  
      case task.current_importance
      when 7: todo.priority = 1 # highest
      when 6: todo.priority = 2
      when 5: todo.priority = 4
      when 4: todo.priority = 5 # medium
      when 3: todo.priority = 6
      when 2: todo.priority = 8
      when 1: todo.priority = 9 # lowest
      end
		  
		  
      @ical.add_todo(todo)
    end
		
    @cal_string = @ical.to_ical
		
    render(:layout => false, :content_type => 'text/calendar')
  end
	
	
  
	
  def teamworkload
    # Shows a workload filtered to just one team
    @person = Person.find(session[:person].id)
		
    @team = Team.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = ?", session[:person].id, @team.id]
    if @check.empty?
      flash[:notice] = "You cannot view this team's workload because you are not a team member."
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id
    else
    
      @mytimezone = TimeZone.new(@person.timezone_name)
      @datetoday = Date.parse(@mytimezone.today().to_s)
      
      if session[:preference].nil?
        session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      end
      
      @preference = session[:preference]
      
      
      begin
        @workload_columns = @preference.workload_columns
        @enable_js = @preference.enable_js
        @quick_edit_options = @preference.quick_edit_options
        @order_by = @preference.workload_order_by
        @refreshrate = @preference.workload_refresh
      rescue
        session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
        @preference = session[:preference]
        
        @workload_columns = @preference.workload_columns
        @enable_js = @preference.enable_js
        @quick_edit_options = @preference.quick_edit_options
        @order_by = @preference.workload_order_by
        @refreshrate = @preference.workload_refresh
      end
      
      
      # step 1: read and set the variables you'll need
      page = (params[:page] ||= 1).to_i
      items_per_page = session[:preference].workload_page_size.to_i
      offset = (page - 1) * items_per_page
      
      # step 2: do your custom find without doing any kind of limits or offsets
      #  i.e. get everything on every page, don't worry about pagination yet
      # @items = Item.find_with_some_custom_method(@some_variable)
      if session[:preference].workload_display == "All tasks"
        if @order_by == "Due date"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and list_id in (select id from lists where team_id = ?) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @team.id], :page => page, :per_page => items_per_page)
				
        elsif @order_by == "Importance"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and list_id in (select id from lists where team_id = ?) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", @team.id], :page => page, :per_page => items_per_page)
        end
			
      elsif session[:preference].workload_display == "Only today's tasks"
        if @order_by == "Due date"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id = ?) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @datetoday, @person.id, @team.id], :page => page, :per_page => items_per_page)

        elsif @order_by == "Importance"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id = ?) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", @datetoday, @person.id, @team.id], :page => page, :per_page => items_per_page)
        end
        
        
      elsif session[:preference].workload_display == "Only my tasks"
        if @order_by == "Due date"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id = ?) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @person.id, @team.id], :page => page, :per_page => items_per_page)
          
        elsif @order_by == "Importance"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id = ?) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", @person.id, @team.id], :page => page, :per_page => items_per_page)
        end
        
        
      else
        if @order_by == "Due date"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and person_id = ? and list_id in (select id from lists where team_id = ?) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", session[:preference].workload_display, @team.id], :page => page, :per_page => items_per_page)
          
        elsif @order_by == "Importance"
          @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and person_id = ? and list_id in (select id from lists where team_id = ?) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", session[:preference].workload_display, @team.id], :page => page, :per_page => items_per_page)
        end
      end

      # step 3: create a Paginator, the second variable has to be the number of ALL items on all pages
      # @item_pages = Paginator.new(self, @items.length, items_per_page, page)
      # @workload_task_pages = Paginator.new(self, @workload_tasks.length, items_per_page, page)

      # step 4: only send a subset of @items to the view
      # this is where the magic happens... and you don't have to do another find
      # @items = @items[offset..(offset + items_per_page - 1)]
      # @workload_tasks = @workload_tasks[offset..(offset + items_per_page -1)]
      
    end
  end
  
  
  def lists
    @team = Team.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = ?", session[:person].id, @team.id]
    if @check.empty?
      output = "You cannot view this team's lists because you are not a team member."
    else
      output = ""
      @team.lists.each do |list|
        output += "<li>"
        output += link_to_list(list, 'picturelink')
        output += "</li>"
      end
    end
    
    render(:text => output, :layout => false)
    
  end
	
  
end
