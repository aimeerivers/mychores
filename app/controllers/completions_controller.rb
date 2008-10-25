class CompletionsController < ApplicationController

	before_filter :login_required

	def index
		redirect_to :action => 'today'
	end
	
	
	
	
  
	def today
  		@person = Person.find(session[:person].id)
		
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
		
  		@completions = Completion.find_by_sql ["select * from completions where date_completed = ? and person_id = ? order by created_on desc", @datetoday, @person.id]
	end
  
	def sevendays
  		@person = Person.find(session[:person].id)
		
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
		
  		unless @person.status.nil?
  			@completions = Completion.find_by_sql ["select * from completions where date_completed >= DATE_SUB(?,INTERVAL 6 DAY) and date_completed <= ? and person_id = ? order by date_completed desc, created_on desc", @datetoday, @datetoday, @person.id ]
  		end
	end
  
	def month
  		@person = Person.find(session[:person].id)
		
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
		
  		unless @person.status.nil?
  			@completions = Completion.find_by_sql ["select * from completions where MONTH(date_completed) = MONTH(?) and YEAR(date_completed) = YEAR(?) and person_id = ? order by date_completed desc, created_on desc", @datetoday, @datetoday, @person.id ]
  		end
	end
	
	
	
	def list
	
	  @person = Person.find(session[:person].id)
	  
	  @mytimezone = TimeZone.new(@person.timezone_name)
	  @datetoday = Date.parse(@mytimezone.today().to_s)
	  @timenow = Time.parse(@mytimezone.now().to_s)
	  
	  @task = Task.find(params[:id])
      @list = List.find(@task.list_id)
      @team = Team.find(@list.team_id)
      
 		# step 1: read and set the variables you'll need
		page = (params[:page] ||= 1).to_i
		items_per_page = 20
		offset = (page - 1) * items_per_page

		# step 2: do your custom find without doing any kind of limits or offsets
		#  i.e. get everything on every page, don't worry about pagination yet
		# @items = Item.find_with_some_custom_method(@some_variable)
		@completions = Completion.paginate(:all, :conditions => [ "task_id = ?", @task.id], :order => "date_completed DESC, created_on DESC", :page => page, :per_page => items_per_page)
		
		
		# Do a nice Google chart!
		
    @completions_for_chart = []
    @months = [] 
    
    i = 12
    loop do
      @completions_for_chart[i] = Completion.count(:conditions => [ "task_id = ? and MONTH(date_completed) = MONTH(?) and YEAR(date_completed) = YEAR(?)" , @task.id, @timenow.months_ago(i), @timenow.months_ago(i) ] )
      @months[i] = (@timenow.months_ago(i)).localize("%b")
      i -= 1
      break if i < 0
    end
    
    max = @completions_for_chart.max
    
    @completions_chart = GoogleChart.new
    @completions_chart.type = :bar_vertical_stacked
    @completions_chart.data = @completions_for_chart.reverse
    @completions_chart.labels = @months.reverse
    @completions_chart.y_labels = [0, max]
    @completions_chart.max_data_value = max
    @completions_chart.width = 400
    @completions_chart.height = 180
    @completions_chart.colors = '60abf1'
    @completions_chart.title = "Completions per month"
    
    
    @days_in_month = ::Time.days_in_month(@timenow.month.to_i, @timenow.year.to_i)
    @day_today = @timenow.mday
  
	end
	
	
	
	def undo		
		@person = Person.find(session[:person].id)
		@completion = Completion.find(params[:id])
		
		# What's the task?
		@task = @completion.task
		
		# Check whether they are a member of the task's team.
		@membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @task.list.team.id ])
		unless @membership_search.nil?
		
			# Most recent completion for that task
			@mrc = Completion.find(:first, :conditions => ["task_id = ?", @task.id], :order => "date_completed desc, created_on desc")
			
			task_date_changed = false
			
			if @completion.id == @mrc.id
				# User is asking to remove the most recent completion for a task.
				# Therefore we set the due date of the task back to the date last completed.
				
				@task.next_due = @completion.date_completed
				
				# Account for one-off tasks to become active again.
				@task.status = 'active'
				
				# What if it's a rotating assignment task?
				if @task.rotate == true
					# Re-assign it back to the person who last completed it.
					@task.person_id = @completion.person_id
				end
				
				# Save all changes.
				@task.save
				
				task_date_changed = true
				new_task_date = @completion.date_completed
			else
			
				# User is removing a completion which is not the most recent.
				task_date_changed = false
			end
			
			@completion.destroy
			
			# Work out the flash messages
			if task_date_changed == true
				flash[:notice] = "The completion was removed and the task's due date was reset to " + new_task_date.strftime("%d %b %Y") + "."
			else
				flash[:notice] = "The completion was removed."
			end
			
			# Re-direct back wherever they came from.
			if params[:return]
			
				if params[:return] == 'task'
					redirect_to :controller => 'tasks', :action => 'show', :id => @task.id
				elsif params[:return] == 'today'
					redirect_to :controller => 'completions', :action => 'today'
				elsif params[:return] == 'sevendays'
					redirect_to :controller => 'completions', :action => 'sevendays'
				elsif params[:return] == 'month'
					redirect_to :controller => 'completions', :action => 'month'
				else
					# Don't really know where they want to go!
					redirect_to :controller => 'tasks', :action => 'workload'
				end
			
			else
				redirect_to :controller => 'tasks', :action => 'workload'
			end
			
		else
			# Naughty, naughty!
			flash[:notice] = "You cannot remove that completion because you are not a confirmed member of the team."
			redirect_to :controller => 'tasks', :action => 'workload'
		end
		
	end

end
