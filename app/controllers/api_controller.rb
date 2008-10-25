class ApiController < ApplicationController


  before_filter :authenticate, :except => [:site_statistics, :logout, :index]


  def index
    # Send straight to the template
  end
  
  def logout
    # Works automagically
    session[:api_user] = nil
  end
  
  def verify_credentials
    data = Hash.new
    data["valid"] = true
    respond_to do |format|
      format.xml { render(:text => data.to_xml) }
      format.json { render(:text => data.to_json) }
    end
  end

  def site_statistics
    
    @title = "MyChores site-wide statistics"
    @timenow = Time.now
    
    @people_count = Person.count(:conditions => 'usertype = 1')
    @task_count = Task.count
    @list_count = List.count
    @team_count = Team.count
    
    @timezone_count = Person.count_by_sql("select count(distinct(timezone_name)) from people where usertype = 1")
    
    @donetoday = Completion.count(:conditions => [ "date_completed = CURDATE()" ] )
    @doneyesterday = Completion.count(:conditions => [ "date_completed = DATE_SUB(CURDATE(), INTERVAL 1 DAY)" ] )
    @donesevendays = Completion.count(:conditions => [ "date_completed > DATE_SUB(CURDATE(), INTERVAL 7 DAY) and date_completed <= CURDATE()" ] )
    @donethismonth = Completion.count(:conditions => [ "MONTH(date_completed) = MONTH(CURDATE()) and YEAR(date_completed) = YEAR(CURDATE())" ] )
    
    data = Hash.new
    data["title"] = @title
    data["timestamp"] = @timenow.to_s
    
    totals = Hash.new
    totals["people"] = @people_count
    totals["timezones"] = @timezone_count
    totals["tasks"] = @task_count
    totals["lists"] = @list_count
    totals["teams"] = @team_count
    data["totals"] = totals
    
    completions = Hash.new
    completions["today"] = @donetoday
    completions["yesterday"] = @doneyesterday
    completions["sevendays"] = @donesevendays
    completions["month"] = @donethismonth
    data["completions"] = completions

    
    respond_to do |format|
    
      format.xml {
        render(:text => data.to_xml)
      }
      
      format.json {        
        render(:text => data.to_json)
      }
    end
    
  end
  
  
  

  def person_details
    
    begin
    
      if params[:login]
        @person = Person.find_by_login(params[:login])
      elsif params[:id]
        @person = Person.find(params[:id])
        
      else # No params - so just return the api user
        @person = Person.find(session[:api_user])
      end
        
    
    rescue
      # Gotta have this to stop Rails from crashing
    end
    
    unless @person.nil?
      @preference = @person.preference
    
      data = Hash.new
      
      data["id"] = @person.id
      data["login"] = @person.login
      data["name"] = @person.name
      data["timezone"] = @person.timezone_name
      data["status"] = @person.status unless @person.status.nil?
      data["type"] = lookup_usertype(@person)
      
      preferences = Hash.new
      
      preferences["date_format"] = @preference.my_date_format
      if @preference.workload_order_by == "Due date"
        preferences["workload_order_by"] = "date"
      else
        preferences["workload_order_by"] = "importance"
      end
      preferences["workload_display"] = @preference.workload_display
      preferences["page_size"] = @preference.workload_page_size
      preferences["mobile_page_size"] = @preference.mobile_page_size
      preferences["enable_javascript"] = @preference.enable_js
      preferences["language_code"] = @preference.language_code
      
      data["preferences"] = preferences
    
      respond_to do |format|
      
        format.xml {
          render(:text => data.to_xml)
        }
        
        format.json {          
          render(:text => data.to_json)
        }
      end
      
    else
      # Give the 404 not found response
      render(:partial => 'response', :layout => false, :status => 404)
    end
    
  end
  
  
  

  def all_tasks
  
    @person = Person.find_by_id(session[:api_user].id)
  
    # Defaults
    @order_by = "date"
    @perpage = 20
    @page = 1
    
    
    if params[:order_by]
      if params[:order_by].downcase == "importance"
        @order_by = "importance"
      end
    end
    
    if params[:per_page]
      @perpage = params[:per_page].to_i
    end
    
    if params[:page]
      @page = params[:page].to_i
    end
    
    @skip = (@perpage * @page) - @perpage
    # eg (10 * 3) - 10 = 20
      
    
    # Now do the query
    if @order_by == "date"
	   @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit ?, ?", @person.id, @skip, @perpage]
	   elsif @order_by == "importance"
	   @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC limit ?, ?", @person.id, @skip, @perpage]
	   end
	   
	  
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
		
		counter = Task.count_by_sql(["select count(*) from tasks where status='active' and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", @person.id])
		
		data = generate_workload(@workload_tasks, counter)
    
    respond_to do |format|
    
      format.xml {
        #render(:layout => false, :content_type => 'application/xml')
        render(:text => data.to_xml)
      }
      
      format.json {
        render(:text => data.to_json)
      }
    end
      
    
  end
  
  
  

  def my_tasks
  
    @person = Person.find_by_id(session[:api_user].id)
  
    # Defaults
    @order_by = "date"
    @perpage = 20
    @page = 1
    
    
    if params[:order_by]
      if params[:order_by].downcase == "importance"
        @order_by = "importance"
      end
    end
    
    if params[:per_page]
      @perpage = params[:per_page].to_i
    end
    
    if params[:page]
      @page = params[:page].to_i
    end
    
    @skip = (@perpage * @page) - @perpage
    # eg (10 * 3) - 10 = 20
      
    
    # Now do the query
    if @order_by == "date"
	   @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit ?, ?", @person.id, @person.id, @skip, @perpage]
	   elsif @order_by == "importance"
	   @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC limit ?, ?", @person.id, @person.id, @skip, @perpage]
	   end
	   
	  
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
		
		counter = Task.count_by_sql(["select count(*) from tasks where status='active' and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", @person.id, @person.id])
		
		data = generate_workload(@workload_tasks, counter)
    
    respond_to do |format|
    
      format.xml {
        #render(:layout => false, :content_type => 'application/xml')
        render(:text => data.to_xml)
      }
      
      format.json {
        render(:text => data.to_json)
      }
    end
      
    
  end
  
  
  

  def todays_tasks
  
    @person = Person.find_by_id(session[:api_user].id)
  
    # Defaults
    @order_by = "date"
    @perpage = 20
    @page = 1
    
    
    if params[:order_by]
      if params[:order_by].downcase == "importance"
        @order_by = "importance"
      end
    end
    
    if params[:per_page]
      @perpage = params[:per_page].to_i
    end
    
    if params[:page]
      @page = params[:page].to_i
    end
    
    @skip = (@perpage * @page) - @perpage
    # eg (10 * 3) - 10 = 20
      
	  
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
    
    # Now do the query
    if @order_by == "date"
	   @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC limit ?, ?", @datetoday, @person.id, @person.id, @skip, @perpage]
	   elsif @order_by == "importance"
	   @workload_tasks = Task.find_by_sql ["select * from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by current_importance DESC, next_due ASC, list_id ASC, name ASC limit ?, ?", @datetoday, @person.id, @person.id, @skip, @perpage]
	   end
	   
	  counter = Task.count_by_sql(["select count(*) from tasks where status='active' and next_due = ? and (person_id = ? or person_id is null) and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1)))", @datetoday, @person.id, @person.id])
	   
	  data = generate_workload(@workload_tasks, counter)
    
    respond_to do |format|
    
      format.xml {
        #render(:layout => false, :content_type => 'application/xml')
        render(:text => data.to_xml)
      }
      
      format.json {
        render(:text => data.to_json)
      }
    end
      
    
  end
  
  
  def tasks
  
    case request.method
    
    when :put
    
    @person = Person.find_by_id(session[:api_user].id)
		@mytimezone = TimeZone.new(@person.timezone_name)
		@datetoday = Date.parse(@mytimezone.today().to_s)
		
		begin
      task = Task.find(params[:id])
    rescue
      # task not found
    end
    
    if task.nil?
      # Give the 404 not found response
      render(:partial => 'response', :layout => false, :status => 404)
    else
    
      membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", @person.id, task.list.team.id ])
      
      if membership_search.nil?
        # Give the 404 not found response
        render(:partial => 'response', :layout => false, :status => 404)
      else
        data = Hash.new
        
        data["task_name"] = task.name
        data["task_description"] = task.description
        data["task_id"] = task.id
        data["task_url"] = "http://www.mychores.co.uk/tasks/show/" + task.id.to_s
        data["task_due_date"] = task.next_due.to_s
        data["task_formatted_due_date"] = formatted_date(task.next_due)
        data["task_time_from_today"] = time_from_today(task.next_due, @datetoday)
        data["task_recurrence"] = task.recurrence_description
        data["task_importance"] = task.current_importance
        data["task_status"] = task.status
        
        unless task.picture.nil?
          data["task_picture"] = "http://www.mychores.co.uk/pictures/" + task.picture.id.to_s + "/" + task.picture.filename
        end
        
        list_hash = Hash.new
        list_hash["list_name"] = task.list.name
        list_hash["list_id"] = task.list.id
        list_hash["list_url"] = "http://www.mychores.co.uk/lists/show/" + task.list.id.to_s
        data["list"] = list_hash
        
        team_hash = Hash.new
        team_hash["team_name"] = task.list.team.name
        team_hash["team_id"] = task.list.team.id
        team_hash["team_url"] = "http://www.mychores.co.uk/teams/show/" + task.list.team.id.to_s
        data["team"] = team_hash
        
        unless task.person.nil?
          unless task.person.id == 0
            assignment_hash = Hash.new
            assignment_hash["person_type"] = lookup_usertype(task.person)
            assignment_hash["person_id"] = task.person.id
            assignment_hash["person_name"] = task.person.name
            assignment_hash["person_login"] = task.person.login
            assignment_hash["person_url"] = "http://www.mychores.co.uk/person/" + task.person.login
            data["assignment"] = assignment_hash
          end
        end
        
        @last_completion = Completion.find(:first, :conditions => [ "task_id = ?", task.id], :order => "date_completed DESC, created_on DESC", :limit => 1)
        
        unless @last_completion.nil?
          completion_hash = Hash.new
          completion_hash["date"] = @last_completion.date_completed.to_s
          completion_hash["formatted_date"] = formatted_date(@last_completion.date_completed)
          completion_hash["time_from_today"] = time_from_today(@last_completion.date_completed, @datetoday)
          
          completion_person_hash = Hash.new
          completion_person_hash["person_type"] = lookup_usertype(@last_completion.person)
          completion_person_hash["person_id"] = @last_completion.person.id
          completion_person_hash["person_name"] = @last_completion.person.name
          completion_person_hash["person_login"] = @last_completion.person.login
          completion_person_hash["person_url"] = "http://www.mychores.co.uk/person/" + @last_completion.person.login
          
          completion_hash["done_by"] = completion_person_hash
          data["last_done"] = completion_hash
        end
        
        
      
        respond_to do |format|
          format.xml { render(:text => data.to_xml) }
          format.json { render(:text => data.to_json) }
        end
        
      end
      
    end
    
    end
  
  end
  
  
  
  
  
  private
  
  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
      session[:api_user] = Person.authenticate(user_name, password)
    end
  end
  
  
  def generate_workload(workload_tasks, counter)
  
	
    i = 0
    data = Hash.new
    data["total_number"] = counter
    tasks = []
    for task in @workload_tasks
      tasks[i] = Hash.new
      
      tasks[i]["task_name"] = task.name
      tasks[i]["task_description"] = task.description
      tasks[i]["task_id"] = task.id
      tasks[i]["task_url"] = "http://www.mychores.co.uk/tasks/show/" + task.id.to_s
      tasks[i]["task_due_date"] = task.next_due.to_s
      tasks[i]["task_formatted_due_date"] = formatted_date(task.next_due)
      tasks[i]["task_time_from_today"] = time_from_today(task.next_due, @datetoday)
      tasks[i]["task_recurrence"] = task.recurrence_description
      tasks[i]["task_importance"] = task.current_importance
      
      unless task.picture.nil?
        tasks[i]["task_picture"] = "http://www.mychores.co.uk/pictures/" + task.picture.id.to_s + "/" + task.picture.filename
      end
      
      list_hash = Hash.new
      list_hash["list_name"] = task.list.name
      list_hash["list_id"] = task.list.id
      list_hash["list_url"] = "http://www.mychores.co.uk/lists/show/" + task.list.id.to_s
      tasks[i]["list"] = list_hash
      
      team_hash = Hash.new
      team_hash["team_name"] = task.list.team.name
      team_hash["team_id"] = task.list.team.id
      team_hash["team_url"] = "http://www.mychores.co.uk/teams/show/" + task.list.team.id.to_s
      tasks[i]["team"] = team_hash
      
      unless task.person.nil?
        unless task.person.id == 0
          assignment_hash = Hash.new
          assignment_hash["person_type"] = lookup_usertype(task.person)
          assignment_hash["person_id"] = task.person.id
          assignment_hash["person_name"] = task.person.name
          assignment_hash["person_login"] = task.person.login
          assignment_hash["person_url"] = "http://www.mychores.co.uk/person/" + task.person.login
          tasks[i]["assignment"] = assignment_hash
        end
      end
      
      i += 1
    end
    
    data["tasks"] = tasks
    
    return data
  end
  
  
  def lookup_usertype(person)
    case person.usertype
    when 1
      return "standard"
    when 2
      return "virtual"
    when 3
      return "deleted"
    when 4
      return "kid"
    else
      return "unknown"
    end
  end
  


end
