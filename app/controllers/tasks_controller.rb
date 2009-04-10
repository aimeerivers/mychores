require 'net/http'
require 'uri'


class TasksController < ApplicationController
  include DateFormatHelper
  
  before_filter :login_required
  before_filter :find_current_date,
    :except => [:index, :list, :chooselist, :progress, :create, :edit, :update, :destroy, :multipledelete, :nudge]
  
  def index
    redirect_to :action => 'workload'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify(:method => :post, :only => [ :nudge_do ], :redirect_to => { :action => :workload })

  def list
    redirect_to :action => 'workload'
  end

  def show
    @task = Task.find(params[:id])
    @list = List.find(@task.list_id)
    @team = Team.find(@list.team_id)
    
	  
    @person = Person.find(session[:person].id)
    @importance = Importance.find_by_value(@task.current_importance)
    
    
    
		
    @preference = session[:preference]
	
    begin
      @enable_js = @preference.enable_js
      @quick_edit_options = @preference.quick_edit_options
    rescue
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      @preference = session[:preference]
      @enable_js = @preference.enable_js
      @quick_edit_options = @preference.quick_edit_options
    end
    
    @completions = Completion.find(:all, :conditions => [ "task_id = ?", @task.id], :order => "date_completed DESC, created_on DESC", :limit => 5)
    @completions_count = Completion.count(:conditions => [ "task_id = ?", @task.id] )
    
    @tips = Tip.find_tagged_with(@task.name.split, :order => 'effectiveness desc, id desc', :limit => 10)
    
  end

  def new
    if params[:list]
      @list = List.find(params[:list])
      @team = Team.find(@list.team_id)
      @task = Task.new
      @person = Person.find(session[:person].id)
		
      @task.next_due = @datetoday
      @memberships = @team.memberships
			
      @importances = Importance.find(:all, :order=>"value desc")
			
			
      # Set up default values from task template
      @preference = Preference.find(:first, :conditions => ["person_id = ?", @person.id ])
			
      @task.one_off = @preference.template_one_off
      @task.recurrence_interval = @preference.template_recurrence_interval
      @task.recurrence_measure = @preference.template_recurrence_measure
      @task.recurrence_occur_on = @preference.template_recurrence_occur_on
      @task.default_importance = @preference.template_importance
      @task.current_importance = @preference.template_importance
      @task.task_missed_options = @preference.template_task_missed_options
    else
      redirect_to :action => 'chooselist'
    end
  end
  
  def chooselist
  end
  
  def progress
    render(:layout => false)
  end
  
  def create
    @task = Task.new(params[:task])
    
    if params[:occur_on]
      @task.recurrence_occur_on = params[:occur_on]
    else
      # If no days ticked assume all.
      @task.recurrence_occur_on = "0,1,2,3,4,5,6"
    end
    	
    # Escalation options
    if params[:task_missed_options]
      @task.task_missed_options = params[:task_missed_options]
    else
      # It is possible that they don't want anything to happen.
      @task.task_missed_options = ""
    end
    	
    	
    @task.describe_recurrence
    if @task.save
      redirect_to :action => 'show', :id => @task.id
    else
      flash[:notice] = 'Sorry, your task was not saved, please try again.'
      redirect_to :action => 'new', :list => params[:task][:list_id]
    end
		
		
    	
  end



  def edit
    @person = Person.find(session[:person].id)
    @task = Task.find(params[:id])
    @list = List.find(@task.list_id)
    @team = Team.find(@list.team_id)
    @otherlists = @team.lists
    @memberships = @team.memberships
    @importances = Importance.find(:all, :order=>"value desc")
  end

  def update
    @task = Task.find(params[:id])
    if @task.update_attributes(params[:task])
      # Also update the occur on days
      if params[:occur_on]
        @task.recurrence_occur_on = params[:occur_on]
      else
        # If no days ticked assume all.
        @task.recurrence_occur_on = "0,1,2,3,4,5,6"
      end
    	
      # Escalation options
      if params[:task_missed_options]
        @task.task_missed_options = params[:task_missed_options]
      else
        # It is possible that they don't want anything to happen.
        @task.task_missed_options = ""
      end
    	
      # Reset the escalation date
      @task.escalation_date = @task.next_due + 1
    	
      # Update the recurrence description
      @task.describe_recurrence
    	
      @task.save
      redirect_to :action => 'show', :id => @task.id
    else
      @person = Person.find(session[:person].id)
      @list = List.find(@task.list_id)
      @team = Team.find(@list.team_id)
      @otherlists = @team.lists
      @memberships = @team.memberships
      @importances = Importance.find(:all, :order=>"value desc")
      render :action => 'edit'
    end
  end
  
  

  def quickcreate
    @person = Person.find(session[:person].id)
		
    if params[:list]
      @defaultlist = params[:list]
    else
      @defaultlist = 0
    end
  end
	
  def multiplecreate
    @person = Person.find(session[:person].id)
		
    @preference = Preference.find(:first, :conditions => ["person_id = ?", @person.id ])
		
    @numbercreated = 0
    @numberfailed = 0
		
    if params[:list] && params[:tasks]
      @list = List.find(params[:list])
		
      # Check that they are a member of the team
      @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @list.team.id ])
      unless @membership_search.nil?
			
        # get each line entered into an array
        @lines = params[:tasks].split(%r{\n})
				
        for line in @lines
				
          # split up the line based on the position of the dash
          linearray = line.split(" -")
          if linearray.length > 0
					
            # pick out task name
            taskname = linearray[0]
						
            if linearray.length > 1
              # pick out recurrence
              recurrence = linearray[1]
              # ensure recurrence is in lower-case.
              recurrence.downcase!
							
              if linearray.length > 2
                # first look for the keyword 'tomorrow'
                if (linearray[2]).match("tomorrow").nil? == false
                  nextdue = @datetoday + 1
                else
							
                  # try to parse it as a date
                  begin
                    nextdue = Date.parse(linearray[2])
                  rescue
                    # so it didn't parse. Use today instead.
                    nextdue = @datetoday
                  end
                end
              else
                # they didn't enter a due date, so make it today.
                nextdue = @datetoday
              end
							
            else
              # they didn't enter a recurrence, so use the user's task template.
              if @preference.template_one_off == true
                recurrence = "one-off"
              else
                recurrence = "every " + @preference.template_recurrence_interval.to_s + " " + @preference.template_recurrence_measure
              end
							
              # ... and make it due today.
              nextdue = @datetoday
            end
						
          else
            # can't process this line.
            taskname = ""
          end
					
          unless taskname == ""
					
            # create the task
            @newtask = Task.new
						
            @newtask.name = taskname
            @newtask.description = ""
						
            @newtask.list_id = params[:list].to_i
            @newtask.status = "active"
            @newtask.rotate = 0
						
            # Attempt to find "one-off" within the recurrence.
            if recurrence.match("one").nil? == false and recurrence.match("off").nil? == false
              @newtask.one_off = 1
            else
              @newtask.one_off = 0
							
              # So it's not one-off then what is it ...
              if recurrence.match("day").nil? == false
                @newtask.recurrence_measure = "days"
								
              elsif recurrence.match("week").nil? == false
                @newtask.recurrence_measure = "weeks"
								
              elsif recurrence.match("month").nil? == false
                @newtask.recurrence_measure = "months"
              else
                # can't match anything else, so just make it days.
                @newtask.recurrence_measure = "days"
              end
							
              # Now try to find the recurrence interval
              # Eeek. This is horrible.
							
              interval = 1 # Assume 1 unless found otherwise
              recurrence_found = false
							
              # There's always the chance that they typed 'Every other day'
              # meaning every 2 days ...
              if recurrence.match("other").nil? == false
                interval = 2
                recurrence_found = true
              end
							
              while recurrence.length > 0 and recurrence_found == false
                # Can it be turned into an integer?
                if recurrence.to_i > 0 then
                  # Hurrah! It converted to an integer!
                  interval = recurrence.to_i
                  recurrence_found = true
                else
                  # Bad luck - it didn't convert.
                  # Chop off a character from the beginning and try again.
                  # The only way to remove a character from the beginning
                  # is to reverse it and chop!
                  recurrence.reverse!
                  recurrence.chop!
                  recurrence.reverse!
                end
              end
							
              # Having done all that ...
              # Either interval will have been set correctly
              # Or it will have remained at 1.
							
              @newtask.recurrence_interval = interval
            end
						
            # We don't have specific days or dates of month
            @newtask.any_day = 1
            @newtask.any_date = 1
						
            # Set the due date as found above.
            @newtask.next_due = nextdue
						
            # Apply other settings from the user's task template
            @newtask.recurrence_occur_on = @preference.template_recurrence_occur_on
            @newtask.default_importance = @preference.template_importance
            @newtask.current_importance = @preference.template_importance
            @newtask.task_missed_options = @preference.template_task_missed_options
						
            # Mark that it was made by Quick-create for future debugging ...!
            @newtask.quickcreate = 1
						
            # Give it a recurrence description
            @newtask.describe_recurrence
						
            # And attempt to save ...
            if @newtask.save
              @numbercreated = @numbercreated + 1
            else
              @numberfailed = @numberfailed + 1
            end
						
          end
        end
				
      end
    end
    render(:layout => false)
  end
	
	
	

  def destroy
    @task = Task.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = (select team_id from lists where id = (select list_id from tasks where id = ?))", session[:person].id, @task.id]
    if @check.empty?
      flash[:notice] = "Task not deleted because you are not a member of the team."
    else
      @task.destroy
      flash[:notice] = "Your task was deleted successfully."
    end
    redirect_to :action => 'workload'
  end
  
  
  
  
  
	
  def workload
    @person = Person.find(session[:person].id)
    @parent = @person.parent
		
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
		
		
		
    @messages = Membership.find_by_sql ["select * from memberships where (confirmed is null or confirmed = 0) and (person_id = ? or team_id in (select team_id from memberships where person_id = ? and confirmed = 1))", @person.id, @person.id]
		
    @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, @person.id, @person.id]
		
		
		
    # step 1: read and set the variables you'll need
    page = (params[:page] ||= 1).to_i
    items_per_page = session[:preference].workload_page_size.to_i
    offset = (page - 1) * items_per_page

    # step 2: do your custom find without doing any kind of limits or offsets
    #  i.e. get everything on every page, don't worry about pagination yet
    # @items = Item.find_with_some_custom_method(@some_variable)
    if session[:preference].workload_display == "All tasks"
      if @order_by == "Due date"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @person.id], :page => page, :per_page => items_per_page)
				
      elsif @order_by == "Importance"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", @person.id], :page => page, :per_page => items_per_page)
      end
			
			
    elsif session[:preference].workload_display == "Only today's tasks"
      if @order_by == "Due date"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @datetoday, @person.id, @person.id], :page => page, :per_page => items_per_page)
				
      elsif @order_by == "Importance"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", @datetoday, @person.id, @person.id], :page => page, :per_page => items_per_page)
      end
			
			
    elsif session[:preference].workload_display == "Only my tasks"
      if @order_by == "Due date"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", @person.id, @person.id], :page => page, :per_page => items_per_page)
				
      elsif @order_by == "Importance"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", @person.id, @person.id], :page => page, :per_page => items_per_page)
      end

    else
      if @order_by == "Due date"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and person_id = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, current_importance DESC, list_id ASC, name ASC", session[:preference].workload_display, @person.id], :page => page, :per_page => items_per_page)
				
      elsif @order_by == "Importance"
        @workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and person_id = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC", session[:preference].workload_display, @person.id], :page => page, :per_page => items_per_page)
      end
    end


  end
  
  
  
  
  
	
  def collage
    @person = Person.find(session[:person].id)
		
    if session[:preference].nil?
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
    end
		
    @preference = session[:preference]
		
		
    begin
      @enable_js = @preference.enable_js
      @refreshrate = @preference.workload_refresh
    rescue
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      @preference = session[:preference]
			
      @enable_js = @preference.enable_js
      @refreshrate = @preference.workload_refresh
    end
		
		
		
    @messages = Membership.find_by_sql ["select * from memberships where (confirmed is null or confirmed = 0) and (person_id = ? or team_id in (select team_id from memberships where person_id = ? and confirmed = 1))", @person.id, @person.id]
		
    @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, @person.id, @person.id]
		
		
    if session[:preference].workload_display == "All tasks"
      @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due <= ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit 24", @datetoday + 1, @person.id]

    elsif session[:preference].workload_display == "Only today's tasks"
      @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit 24", @datetoday, @person.id, @person.id]

    elsif session[:preference].workload_display == "Only my tasks"
      @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due <= ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit 24", @datetoday + 1, @person.id, @person.id]
      
    else
      @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due <= ? and person_id = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit 24", @datetoday + 1, session[:preference].workload_display, @person.id]

    end
		
  end

	
  def matrix
    @person = Person.find(session[:person].id)
    @parent = @person.parent
		
    if session[:preference].nil?
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
    end
		
    @preference = session[:preference]
		
		
    begin
      @enable_js = @preference.enable_js
      @refreshrate = @preference.workload_refresh
    rescue
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      @preference = session[:preference]
			
      @enable_js = @preference.enable_js
      @refreshrate = @preference.workload_refresh
    end
		
		
		
    @messages = Membership.find_by_sql ["select * from memberships where (confirmed is null or confirmed = 0) and (person_id = ? or team_id in (select team_id from memberships where person_id = ? and confirmed = 1))", @person.id, @person.id]
		
    @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, @person.id, @person.id]
		
		
		
    if session[:preference].workload_display == "All tasks"
      @tasks_by_importance = Task.find_by_sql ["select *, datediff(curdate(), next_due) as diff, datediff(curdate(), next_due)  * current_importance as rank from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by rank desc, current_importance desc, list_id ASC, name ASC limit 15", @person.id]
		  
    elsif session[:preference].workload_display == "Only today's tasks"
      @tasks_by_importance = Task.find_by_sql ["select *, datediff(curdate(), next_due) as diff, datediff(curdate(), next_due)  * current_importance as rank from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by rank desc, current_importance desc, list_id ASC, name ASC limit 15", @datetoday, @person.id, @person.id]
		  
    elsif session[:preference].workload_display == "Only my tasks"
      @tasks_by_importance = Task.find_by_sql ["select *, datediff(curdate(), next_due) as diff, datediff(curdate(), next_due)  * current_importance as rank from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by rank desc, current_importance desc, list_id ASC, name ASC limit 15", @person.id, @person.id]
      
    else
      @tasks_by_importance = Task.find_by_sql ["select *, datediff(curdate(), next_due) as diff, datediff(curdate(), next_due)  * current_importance as rank from tasks where status='active' and person_id = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by rank desc, current_importance desc, list_id ASC, name ASC limit 15", session[:preference].workload_display, @person.id]
    end
		
  end
	
		
	
	
  def statistics
    @person = Person.find(session[:person].id)
    @preference = session[:preference]
		
    begin
      @refreshrate = @preference.workload_refresh
    rescue
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      @preference = session[:preference]
			
      @refreshrate = @preference.workload_refresh
    end
		
    @messages = Membership.find_by_sql ["select * from memberships where (confirmed is null or confirmed = 0) and (person_id = ? or team_id in (select team_id from memberships where person_id = ? and confirmed = 1))", @person.id, @person.id]
		
    @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, @person.id, @person.id]
		
    @due_today = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, @person.id, @person.id]
		
    @done_today = Completion.count_by_sql ["select count(*) from completions where date_completed = ? and person_id = ?", @datetoday, @person.id]
		
    @total_number = @number_overdue + @due_today + @done_today
		
    @done_this_week = Completion.count_by_sql ["select count(*) from completions where date_completed >= DATE_SUB(?,INTERVAL 6 DAY) and date_completed <= ? and person_id = ?", @datetoday, @datetoday, @person.id ]
		
    @done_this_month = Completion.count_by_sql ["select count(*) from completions where MONTH(date_completed) = MONTH(?) and YEAR(date_completed) = YEAR(?) and person_id = ?", @datetoday, @datetoday, @person.id ]
		
		
		
    @thirty_day_totals = []
    
    i = 27
    loop do
      @thirty_day_totals[i] = Completion.count(:conditions => [ "date_completed = ? and person_id = ?", @datetoday.advance(:days => -i), @person.id ] )
      i -= 1
      break if i < 0
    end
    
    @thirty_days_max = @thirty_day_totals.max
    
    @thirty_day_chart = GoogleChart.new
    @thirty_day_chart.type = :sparkline
    @thirty_day_chart.line_style = "2,2,1"
    @thirty_day_chart.data = @thirty_day_totals.reverse
    @thirty_day_chart.marker = "B,E6F2FA,0,0,0"
    @thirty_day_chart.max_data_value = @thirty_days_max
    @thirty_day_chart.width = 120
    @thirty_day_chart.height = 20
    @thirty_day_chart.colors = '0077CC'
    @thirty_day_chart.chart_fill = "bg,s,FFFFFF00" # Transparent background
    
    
    @chart_data = []
    @chart_data[0] = @number_overdue
    @chart_data[1] = @due_today
    @chart_data[2] = @done_today
    
    @chart_labels = []
    @chart_labels[0] = "Overdue: #{@number_overdue}"
    @chart_labels[1] = "Due today: #{@due_today}"
    @chart_labels[2] = "Done today: #{@done_today}"
    
    max = @chart_data.max
    
    @chart = GoogleChart.new
    @chart.type = :bar_horizontal_stacked
    @chart.data = [@number_overdue, @due_today, @done_today]
    @chart.labels = [0,max]
    @chart.y_labels = @chart_labels.reverse
    @chart.max_data_value = max
    @chart.width = 300
    @chart.height = 110
    @chart.colors = ["FFD7D7|FFE9BE|DDFFCC"]
    
    
    @pie_chart = GoogleChart.new
    @pie_chart.type = :pie
    @pie_chart.data = [@done_today, @due_today, @total_number-@done_today-@due_today]
    @pie_chart.max_data_value = @pie_chart.data.max
    @pie_chart.width = 70
    @pie_chart.height = 70
    @pie_chart.colors = ["DDFFCC","FFE9BE","FFD7D7"]
	
  end
	
	
	
  def calendar
    @person = Person.find(session[:person].id)
    @enable_js = @person.preference.enable_js
    @preference = session[:preference]
		
    begin
      @refreshrate = @preference.workload_refresh
    rescue
      session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
      @preference = session[:preference]
			
      @refreshrate = @preference.workload_refresh
    end
		
    if params[:year] then
      @year = params[:year]
    else
      @year = @datetoday.year
    end
		
    if params[:month] then
      @month = params[:month]
    else
      @month = @datetoday.month
    end
		
    if @month.to_i == @datetoday.month and @year.to_i == @datetoday.year then
      @marktoday = @datetoday.mday
    else
      @marktoday = 0
    end
		
    if @month.to_i == 12 then
      @forwardmonth = 1
      @forwardyear = @year.to_i + 1
    else
      @forwardmonth = @month.to_i + 1
      @forwardyear = @year
    end

    if @month.to_i == 1 then
      @backmonth = 12
      @backyear = @year.to_i - 1
    else
      @backmonth = @month.to_i - 1
      @backyear = @year
    end
		
		
    @messages = Membership.find_by_sql ["select * from memberships where (confirmed is null or confirmed = 0) and (person_id = ? or team_id in (select team_id from memberships where person_id = ? and confirmed = 1))", @person.id, @person.id]
		
    @number_overdue = Task.count_by_sql ["select count(*) from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) and (person_id = ? or person_id is null)", @datetoday, @person.id, @person.id]
		
    @this_months_tasks = Task.find_by_sql ["select * from tasks where status='active' and MONTH(next_due) = ? and YEAR(next_due) = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC", @month.to_i, @year.to_i, @person.id]
  end
	
	
	
  def print
	
  end
	
	
	
  def printmonth
    @person = Person.find(session[:person].id)
		
    if params[:year] then
      @year = params[:year]
    else
      @year = @datetoday.year
    end
		
    if params[:month] then
      @month = params[:month]
    else
      @month = @datetoday.month
    end
		
    if @month.to_i == 12 then
      @forwardmonth = 1
      @forwardyear = @year.to_i + 1
    else
      @forwardmonth = @month.to_i + 1
      @forwardyear = @year
    end

    if @month.to_i == 1 then
      @backmonth = 12
      @backyear = @year.to_i - 1
    else
      @backmonth = @month.to_i - 1
      @backyear = @year
    end
		
    @this_months_tasks = Task.find_by_sql ["select * from tasks where status='active' and MONTH(next_due) = ? and YEAR(next_due) = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC", @month.to_i, @year.to_i, @person.id]
		
    render(:layout => false)
		
  end
	
	
	
  def printweek
    @person = Person.find(session[:person].id)
    
    if params[:year] then
      @year = params[:year]
    else
      @year = @datetoday.year
    end
		
    if params[:month] then
      @month = params[:month]
    else
      @month = @datetoday.month
    end
		
    if params[:day] then
      @day = params[:day]
    else
      @day = @datetoday.day
    end
		
    @seed_date = Date.parse(@year.to_s + '/' + @month.to_s + '/' + @day.to_s)
		
    @back_date = @seed_date - 7
    @forward_date = @seed_date + 7
		
    @backyear = @back_date.year
    @backmonth = @back_date.month
    @backday = @back_date.day
		
    @forwardyear = @forward_date.year
    @forwardmonth = @forward_date.month
    @forwardday = @forward_date.day
		
    @day_of_week = @seed_date.wday
		
    @start_of_week = @seed_date - @day_of_week
    @end_of_week = @start_of_week + 6
		
		
    @this_weeks_tasks = Task.find_by_sql ["select * from tasks where status='active' and WEEK(next_due) = WEEK(?) and YEAR(next_due) = YEAR(?) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC", @seed_date, @seed_date, @person.id]
		
    render(:layout => false)
		
  end
	
	
	
  def printtodo
    @person = Person.find(session[:person].id)
		
    @overdue_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due < ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC", @datetoday, @person.id]
		
    @todays_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by list_id ASC, name ASC", @datetoday, @person.id]
		
    render(:layout => false)
		
  end
	
	
	
	
  def markdone
    @task = Task.find(params[:id])
    @list = List.find(@task.list_id)
    @team = Team.find(@list.team_id)
		
    @teammembers = Person.find_by_sql ["select * from people where usertype != 3 and id in (select person_id from memberships where confirmed = 1 and  team_id = ?) order by login ASC", @team.id]
		
    @person = Person.find(session[:person].id)
  end
	
	
	
  def done
    # Get the parameters
    @task = Task.find(params[:id])
    @team = @task.list.team
		
    @person = Person.find(session[:person].id)
		
		
		
    # Check that they're actually allowed to update that task!
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @task.list.team.id ])
    unless @membership_search.nil?
		
      # Assume no Twitter update unless all the circumstances align!
      update_twitter = false
			
      # Here come the circumstances ...!
      if @person.preference.twitter_post == true
        unless @person.preference.twitter_email.nil? or @person.preference.twitter_email.empty?
          unless @person.preference.twitter_password.nil? or @person.preference.twitter_password.empty?
            unless @person.preference.twitter_lists.nil?
              if @person.preference.twitter_lists.include?(@task.list.id.to_s)
                update_twitter = true
              end
            end
          end
        end
      end
			
      if params[:completed]
        datecompleted = Date.parse(params[:completed])
        update_twitter = false
      else
        datecompleted = @datetoday
      end
			
      if params[:personcompleted]
        personcompleted = params[:personcompleted]
        update_twitter = false
      else
        personcompleted = @person.id
      end
			
      # All done in the model now.
      flash_message = @task.done(@person, datecompleted, personcompleted, update_twitter)
			
      # Save done before Twitter update.
      # @task.save


      # Our JavaScript requests send params[:flash] = 'none'.
      # In this case can return out and skip the whole rendering thing.
      # Outlook will not send this parameter so it will carry on.
      if params[:flash] and params[:flash] == 'none'
        render :nothing => true
        return
      end

      # We would have used respond_to
      # except that Outlook sends requests via JavaScript.
      # Outlook for the lose.


      flash[:notice] = flash_message
		
      redirect_back
			
    else
      flash[:notice] = "Task not updated because it is not one of your tasks."
      redirect_to :action => 'workload'
    end
		
  end
	
	
	
	
	
	
	
  def skip
    # Get the parameters
    @task = Task.find(params[:id])
    @team = @task.list.team
		
    @person = Person.find(session[:person].id)
		
		
		
    # Check that they're actually allowed to update that task!
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @task.list.team.id ])
    unless @membership_search.nil?
		
      flash_message = @task.reschedule(@datetoday)
      @task.save

      if params[:flash] and params[:flash] == 'none'
        render :nothing => true
        return
      end

      flash[:notice] = flash_message
		
      redirect_back
			
    else
      flash[:notice] = "Task not updated because it is not one of your tasks."
      redirect_to :action => 'workload'
    end
		
  end
	
	
	
	
  def multipleaction
    # Get the parameters
    @tasks = Task.find(:all, :conditions => [ "id in (?)", params[:multiselect]], :order => "next_due ASC, list_id ASC, name ASC")
    action = params[:actionsetting]
		
    @person = Person.find(session[:person].id)
		
    if action == "nudge"
      # Find all members of all your teams
			
      @other_members = Person.find_by_sql ["select * from people where usertype = 1 AND id in (select person_id from memberships where confirmed = 1 and team_id in (select id from teams where id in (select team_id from memberships where confirmed = 1 and person_id = ?))) and id != ? order by login ASC", @person.id, @person.id]
			
      @default_message = @person.name + " would really like you to do these tasks:
      "
			
      for task in @tasks
        @default_message += "
	" + task.list.name + ": " + task.name
      end

      @default_message += "
			
			
Please login to MyChores to tick off your tasks!"
			
      # Show the nudge page
      render :controller => 'tasks', :action => 'nudge'
    else
      datecompleted = @datetoday
      personcompleted = @person.id
			
      # No Twitter updates when multiple done.
      update_twitter = false
			
      number_updated = 0
			
      unless @tasks.empty?
			
        for task in @tasks
          @team = task.list.team
				
          # Check that they're actually allowed to update that task!
          @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, task.list.team.id ])
          unless @membership_search.nil?
				
				
            # Case markdone
						
            if action == "markdone"
              flash_message = task.done(@person, datecompleted, personcompleted, update_twitter)
							
              # Save now done in model
              # task.save
							
							
              # Case skip
							
            elsif action == "skip"
              flash_message = task.reschedule(@datetoday)
              task.save
            end
						
            number_updated += 1
						
          end
					
        end
      end
			
      flash[:notice] = "Tasks updated: " + number_updated.to_s
				
			
      redirect_back
      
    end
		
  end
	
	
	
	
	
  def disactivate
    # Get the parameters
    @task = Task.find(params[:id])
    @team = @task.list.team
		
    @person = Person.find(session[:person].id)
		
    # Check that they're actually allowed to do that task!
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @task.list.team.id ])
    unless @membership_search.nil?
		
      @task.status = 'inactive'
      @task.save
			
      redirect_to :action => 'show', :id => @task.id
			
    else
      flash[:notice] = "Task not made inactive because it is not one of your tasks."
      redirect_to :action => 'workload'
    end
  end
	
	
	
  def activate
    # Get the parameters
    @task = Task.find(params[:id])
    @team = @task.list.team
		
    @person = Person.find(session[:person].id)
		
    # Check that they're actually allowed to do that task!
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @task.list.team.id ])
    unless @membership_search.nil?
		
      @task.status = 'active'
			
      # Set it as due today
      @task.next_due = @datetoday
			
      @task.save
			
      redirect_to :action => 'show', :id => @task.id
			
    else
      flash[:notice] = "Task not made active because it is not one of your tasks."
      redirect_to :action => 'workload'
    end
  end
	
	
	
	
	
  def move
    @person = Person.find(session[:person].id)
		
    @most_overdue = Task.find_by_sql ["select * from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC limit 1", @person.id]
  end
	
  def movetasks
    @moved = 0
    @notmoved = 0
		
    if params[:team] && params[:movewhat]
      # user has selected the teams they want in the team[] parameter
      # Find all tasks in those teams
      @tasks = Task.find_by_sql ["select * from tasks where status='active' and list_id in (select id from lists where team_id in (?))", params[:team] ]
			
      # loop through all the tasks
      for task in @tasks
        if params[:movewhat].include?(task.recurrence_measure)
          task.next_due += params[:moveby].to_i
          task.save
          @moved += 1
        else
          @notmoved += 1
        end
      end
			
    end
		
    render(:layout => false)
  end
	
	
	
	
	
  def multipledelete
    @person = session[:person]
  end
	
  def multipledeletetasks
    @deleted = 0
    @notdeleted = 0
		
    if params[:list]
      # user has selected the lists whose tasks should be deleted
      # First check that they are in fact a member of each of those lists
      @lists = List.find_by_sql ["select * from lists where id in (?)", params[:list] ]
			
      # loop through all the lists
      for list in @lists
        # Are they a member?
        @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = (select team_id from lists where id = ?)", session[:person].id, list.id]
        if @check.empty?
          # Can't delete anything in this list
          @notdeleted += Task.count_by_sql(["select count(*) from tasks where list_id = ?", list.id ])
        else
          @deleted += Task.count_by_sql(["select count(*) from tasks where list_id = ?", list.id ])
          Task.destroy_all([ "list_id = ?", list.id ])
        end
      end
			
    end
		
    render(:layout => false)
  end
	
	
  def export
    @person = session[:person]
  end
	
  def exporttasks
	
    require 'csv'
	
    @person = session[:person]
    @filecreated = false
		
    if params[:team]
      # user has selected the teams they want in the team[] parameter
      # Find the teams
      @teams = Team.find(:all, :conditions => [ "id in (?)", params[:team]], :order => 'name')
			
      unless @teams.empty?
			
        @filename = "mychores-" + @person.login + "-" + Time.now.strftime("%Y%m%d-%H%M%S") + ".csv"
			
        # outfile = File.open("public/exports/#{@filename}", 'a')
        # outfile = File.open("public/exports/#{@filename}", 'w')
        outfile = File.new(RAILS_ROOT + "/public/exports/#{@filename}", "w")
        for team in @teams
          CSV::Writer.generate(outfile) do |csv|
            csv << ["#{team.name} tasks"]
            csv << [nil]
						
            # Find the lists in the team
            @lists = List.find(:all, :conditions => [ "team_id = ?", team.id], :order => 'name')
            unless @lists.empty?
              for list in @lists
                csv << ["#{list.name} tasks", "Recurrence", "Last done", "Last done by", "Assigned to", "Next due", "Description"]
								
                # Find the tasks in the list
                @tasks = Task.find(:all, :conditions => [ "status='active' and list_id = ?", list.id], :order => 'next_due')
                unless @tasks.empty?
                  for task in @tasks
									
                    # Find lastdone
                    lastdoneby = nil
                    lastdone = Completion.find(:first, :conditions => [ "task_id = ?", task.id], :order => 'created_on desc')
                    unless lastdone.nil?
                      lastdoneby = lastdone.person.login
                      lastdone = lastdone.date_completed.strftime("%d %b %Y")
                    end
										
									
                    # Find assignee
                    if task.person_id.nil?
                      assignee = team.name
                    else
                      assignee = Person.find(task.person_id).login
                    end
										
                    csv << ["#{task.short_name}", "#{task.recurrence_description}", "#{lastdone}", "#{lastdoneby}", "#{assignee}", "#{task.next_due.strftime('%d %b %Y')}", "#{task.description}"]
                  end
                else
                  csv << ["(no tasks)"]
                end
                csv << [nil]
                csv << [nil]
              end
            else
              csv << ["(no lists)"]
            end
						
            csv << [nil]
            csv << [nil]
            csv << [nil]
          end
        end
        outfile.close
        @filecreated = true
				
        # send_file("mychores-#{@person.login}.csv", :disposition => 'attachment', :stream => false)
      end
		
    end
    render(:layout => false)
		
  end
	
	

  def nudge
    # Get the parameters
    @task = Task.find(params[:id])
    @list = @task.list
    @team = @list.team
		
    @person = Person.find(session[:person].id)
		
    # Check that they're actually allowed to do that task!
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @team.id ])
		
    unless @membership_search.nil?
		
      @other_members = Person.find_by_sql ["select * from people where usertype = 1 AND id in (select person_id from memberships where confirmed = 1 and team_id = ?) and id != ? order by login ASC", @team.id, @person.id]
			
      @default_message = @person.name + " would really like you to do this task:
			
      " + @list.name + ": " + @task.name + "
	

Please login to MyChores to tick off your tasks!"
			
    else
      flash[:notice] = "You cannot nudge someone to do that task."
      redirect_to :action => 'workload'
    end
  end
	
	
	
  def nudge_do
    # Verification method above ensures this only accepts POST.
    # So all other permissions verifications have already been done.
		
    @persontonudge = Person.find(params[:persontonudge])
    @personnudging = Person.find(session[:person].id)
		
    @email = Email.new
		
    @email.subject = "MyChores nudge from " + @personnudging.name
    @email.message = "Hi " + @persontonudge.name + ",
		
    " + params[:message] + "

Your MyChores login id is: " + @persontonudge.login + "

Forgot your password? Reset it here:
http://www.mychores.co.uk/admin/forgotpassword

http://www.mychores.co.uk"
				      
    @email.to = @persontonudge.email
    @email.save
						
    flash[:notice] = "Your nudge will be sent shortly."
    redirect_to :action => 'workload'
		
  end
	
	
	
  def quickchangepreferences
    # Called from the workload page
		
    @person = Person.find(session[:person].id)
    @preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
		
    if @preference.update_attributes(params[:preference])
      # re-load preferences into session cookies
      session[:preference] = @preference
      flash[:notice] = "Your preferences were updated."
    else
      flash[:notice] = "There was a problem updating your preferences."
    end
		
    redirect_back
    
  end
	
	
	
	

  def changeimportance
    @task = Task.find(params[:id])
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = (select team_id from lists where id = (select list_id from tasks where id = ?))", session[:person].id, @task.id]
    if @check.empty?
      # Do nothing - it's not a task they can update
    else
      @newimportance = params[:importance].to_i
      if @newimportance >= 1 and @newimportance <= 7
        @task.current_importance = @newimportance
        @task.save
      end
    end
    
    # Give back a 200 OK
    render :partial => 'response', :layout => false, :status => 200
  end
  
  
	

  
  
  def change_due_date
    @task = Task.find(params[:id])
    @person = Person.find(session[:person].id)
	
    date = @task.next_due
    
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = (select team_id from lists where id = (select list_id from tasks where id = ?))", session[:person].id, @task.id]
    if @check.empty?
      render(:text => "You are not authorised to do that.")
    else
      @task.next_due = Date.parse(params[:value])
      date = @task.next_due if @task.save
      render(:text => descriptive_date(date, @datetoday))
    end
  end
  
  def change_task_name
    @task = Task.find(params[:id])
    
    previous_name = @task.name
    
    @check = Membership.find_by_sql ["select * from memberships where confirmed = 1 and person_id = ? and team_id = (select team_id from lists where id = (select list_id from tasks where id = ?))", session[:person].id, @task.id]
    if @check.empty?
      render(:text => "You are not authorised to do that.")
    else
      @task.name = params[:value]
      @task.name = previous_name unless @task.save
      render(:text => link_to_task(@task, 'picturelink'))
    end
  end
  
  
  
  def luckydip
    @person = Person.find(session[:person].id)
		
    @number_of_tasks = Task.count(:conditions => ["status='active' and next_due <= ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", @datetoday, @person.id, @person.id])
		
		
    if @number_of_tasks == 0
      flash[:notice] = "You have no tasks that are due."
      redirect_to(:action => 'workload')
    else
      offset = rand(@number_of_tasks)
		
      @random_task = Task.find(:first, :conditions => ["status='active' and next_due <= ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", @datetoday, @person.id, @person.id], :offset => offset)
      flash[:notice] = "A lucky dip task has been chosen for you!"
      redirect_to(:action => 'show', :id => @random_task.id)
    end

  end
	
end
