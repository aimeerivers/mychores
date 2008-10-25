class ListsController < ApplicationController

  before_filter :login_required
	
  def index
    redirect_to :controller => 'tasks', :action => 'workload'
  end
  
  def list
    redirect_to :controller => 'tasks', :action => 'workload'
  end

	def show
		@list = List.find(params[:id])
		@team = Team.find(@list.team_id)
		
		
		@person = Person.find(session[:person].id)
		
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
		
		
		
		# Items should be paginated just like the workload list ...
		# Actually, this is a mini workload list just for the list being shown.
		
		
		# step 1: read and set the variables you'll need
		page = (params[:page] ||= 1).to_i
		items_per_page = session[:preference].workload_page_size.to_i
		offset = (page - 1) * items_per_page

		# step 2: do your custom find without doing any kind of limits or offsets
		#  i.e. get everything on every page, don't worry about pagination yet
		# @items = Item.find_with_some_custom_method(@some_variable)


		if @order_by == "Due date"
			@workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and list_id = ? order by next_due ASC, current_importance DESC, name ASC", @list.id], :page => page, :per_page => items_per_page)
			
		elsif @order_by == "Importance"
			@workload_tasks = Task.paginate_by_sql(["select * from tasks where status='active' and list_id = ? order by current_importance DESC, next_due ASC, name ASC", @list.id], :page => page, :per_page => items_per_page)
		end
			

		# step 3: create a Paginator, the second variable has to be the number of ALL items on all pages
		# @item_pages = Paginator.new(self, @items.length, items_per_page, page)
		# @workload_task_pages = Paginator.new(self, @workload_tasks.length, items_per_page, page)

		# step 4: only send a subset of @items to the view
		# this is where the magic happens... and you don't have to do another find
		# @items = @items[offset..(offset + items_per_page - 1)]
		# @workload_tasks = @workload_tasks[offset..(offset + items_per_page -1)]
    
    
		
		# This was the old way ...
		# @tasks = Task.find(:all, :conditions => [ "status='active' and list_id = ?", @list.id ], :order => "next_due ASC, name ASC")
		
		
		# We still get the inactive tasks like before ...
		@inactivetasks = Task.find(:all, :conditions => [ "status='inactive' and list_id = ?", @list.id ], :order => "next_due DESC, name ASC LIMIT 20")
    
		
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
	end

	def new
		
		if params[:team]
			@defaultteam = params[:team]
		else
			@defaultteam = 0
		end
		
		@list = List.new
	end
  
  def chooseteam
  end

  def create
    @list = List.new(params[:list])
    if @list.save
      redirect_to :action => 'show', :id => @list.id
    else
    	flash[:notice] = 'Sorry, your list was not saved, please try again.'
      redirect_to :action => 'new', :team => params[:list][:team_id]
    end
  end

	def quickcreate
		if params[:team]
			@defaultteam = params[:team]
		else
			@defaultteam = 0
		end
	end
	
	def multiplecreate
		@numbercreated = 0
		@numberfailed = 0
		
		if params[:team] && params[:lists]
			@team = Team.find(params[:team])
			@person = Person.find(session[:person].id)
		
			# Check that they are a member of the team
			@membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @team.id ])
			unless @membership_search.nil?
			
				# split up into list names based on newlines
				@listnames = params[:lists].split(%r{\n})
				
				for listname in @listnames
					unless listname == ""
					
						# if the list name is greater than 25 characters, must truncate it
						listnamelength = listname.length
						while listnamelength > 25
							listname.chop!
							listnamelength = listname.length
						end
					
						# create the list
						@newlist = List.new
						@newlist.name = listname
						@newlist.description = ""
						@newlist.team_id = params[:team].to_i
						@newlist.quickcreate = 1
						if @newlist.save
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

  def edit
    @list = List.find(params[:id])
    @team = Team.find(@list.team_id)
  end

  def update
    @list = List.find(params[:id])
    if @list.update_attributes(params[:list])
      redirect_to :action => 'show', :id => @list
    else
      render :action => 'edit'
    end
  end

  def destroy
    @list = List.find(params[:id])
    @check = Membership.find_by_sql(["select * from memberships where confirmed = 1 and person_id = ? and team_id = (select team_id from lists where id = ?)", session[:person].id, @list.id])
    if @check.empty?
	 	flash[:notice] = "List not deleted because you are not a member of the team."
	 else
	 	@list.destroy
	 	flash[:notice] = "Your list was deleted successfully."
	 end
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def quickassign
    @list = List.find(params[:id])
    @team = Team.find(@list.team_id)
    @memberships = @team.memberships
  end
  
  def reassigntasks
    @list = List.find(params[:id])
    @team = Team.find(@list.team_id)
    rotate = params[:rotate]
    
    unless (params[:person]).empty?
    	@person = Person.find(params[:person])
    else
    	@person = nil
    end
    
    # check for confirmed membership of the team they're trying to update
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", session[:person].id, @team.id ])
    
		unless @membership_search.nil?
    	# allow to continue ...
   
   	 # see if the assignment is valid ...
	    valid = false
	    if @person.nil?
	    	valid = true # just assign it to the team as a whole
	    else
	    	@membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, @team.id ])
	    	unless @membership_search.nil?
	    		valid = true
	    	end
	    end
	    
	    if valid == true
	    	# re-assign all tasks within the list
	    	if @person.nil?
	    		reassign = nil
	    	else
	    		reassign = @person.id
	    	end
	    	
	    	@tasks = @list.tasks
	    	for task in @tasks
	    		task.person_id = reassign
	    		
	    		if reassign == nil
	    			task.rotate = 0
	    			# if they want to assign it back to the whole team
	    			# ensure rotating assignments is switched off.
	    		end
	    		
	    		# but if they've specifically asked for rotating assignments ...
	    		if rotate == "on"
	    			task.rotate = 1
	    			# rotation will be sorted out in the model as each task is saved.
	    		end
	    		
	    		task.save
	    	end
	    	flash[:notice] = "All tasks have been re-assigned as requested."
	
	    else
	    	# return to list; failed to update
	    	flash[:notice] = "Re-assignment failed. Perhaps the assignee is not a member of the team."
	    end
	    
	 else
	 	# Someone tried to update someone else's list
	 	flash[:notice] = "Sorry, you don't have permission to re-assign tasks in this list."
	 end
    
    redirect_to :controller => 'lists', :action => 'show', :id => @list.id
    
  end
  
  
	def reschedule
		@list = List.find(params[:id])
		@team = Team.find(@list.team_id)
		@memberships = @team.memberships
		
  		@person = Person.find(session[:person].id)
		
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
	end
   
	def rescheduletasks
		@list = List.find(params[:id])
		@team = Team.find(@list.team_id)
		
		# check for confirmed membership of the team they're trying to update
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", session[:person].id, @team.id ])
    
		unless @membership_search.nil?
			# allow to continue
			unless (params[:newdate]).empty?
				newdate = Date.parse(params[:newdate])
				
				@tasks = @list.tasks
		    	for task in @tasks
		    		task.next_due = newdate
		    		task.save
		    	end
				
				flash[:notice] = "All tasks have been re-scheduled, as requested."
			else
				# no date or invalid date entered
				flash[:notice] = "Invalid date entered. Tasks not re-scheduled."
			end
		else
		 	# Someone tried to update someone else's list
		 	flash[:notice] = "Sorry, you don't have permission to re-schedule tasks in this list."
		end
		
		redirect_to :controller => 'lists', :action => 'show', :id => @list.id
	end
  
end
