class HomeController < ApplicationController
  
  before_filter :find_current_date, :only => :search

  def welcome_page_calculations
		@numpeople = Person.count(:conditions => "usertype = 1")
		@numtasks = Task.count
		
		@bulletin = Bulletin.find(:first, :order => "created_on desc, updated_on desc")
		
		# Pick a random testimonial
		offset = rand(Testimonial.count(:conditions => 'approved = 1'))
		@testimonial = Testimonial.find :first, :conditions => 'approved = 1', :offset => offset
		
		if session[:person].nil?
		  @datetoday = Date.today
		else
			@person = Person.find(session[:person].id)
			@mytimezone = TimeZone.new(@person.timezone_name)
			@datetoday = Date.parse(@mytimezone.today().to_s)
		end
		
		@donetoday = Completion.count(:conditions => [ "date_completed = ?", @datetoday ] )
		@doneyesterday = Completion.count(:conditions => [ "date_completed = DATE_SUB(?, INTERVAL 1 DAY)", @datetoday ] )
		@donethismonth = Completion.count(:conditions => [ "MONTH(date_completed) = MONTH(?) and YEAR(date_completed) = YEAR(?)" , @datetoday, @datetoday ] )
		
    @thirty_day_totals = []
    
    i = 27
    loop do
      @thirty_day_totals[i] = Completion.count(:conditions => [ "date_completed = ?", @datetoday.advance(:days => -i) ] )
      i -= 1
      break if i < 0
    end
    
    max = @thirty_day_totals.max
    
    
    @thirty_day_chart = GoogleChart.new
    @thirty_day_chart.type = :sparkline
    @thirty_day_chart.line_style = "2,2,1"
    @thirty_day_chart.data = @thirty_day_totals.reverse
    @thirty_day_chart.marker = "B,E6F2FA,0,0,0"
    @thirty_day_chart.max_data_value = max
    @thirty_day_chart.width = 150
    @thirty_day_chart.height = 20
    @thirty_day_chart.colors = '0077CC'
		
	end
	
	def welcome
	  welcome_page_calculations
		session[:referrer] = params[:referrer] if params[:referrer]
	 	session[:code] = params[:code] if params[:code]
	end

	def index
		if session[:person].nil?
			welcome_page_calculations
			
			
			session[:referrer] = params[:referrer] if params[:referrer]
	 		session[:code] = params[:code] if params[:code]
			render :action => 'welcome'
		else
			@loggedon = session[:person]
			if @loggedon.default_view == 'Calendar'
				redirect_to :controller => 'tasks', :action => 'calendar'
			elsif @loggedon.default_view == 'Statistics'
				redirect_to :controller => 'tasks', :action => 'statistics'
			elsif @loggedon.default_view == 'Hot map'
				redirect_to :controller => 'tasks', :action => 'matrix'
			elsif @loggedon.default_view == 'Collage'
				redirect_to :controller => 'tasks', :action => 'collage'
			else
				redirect_to :controller => 'tasks', :action => 'workload'
			end
		end
	end
	
  def search
    if request.method == :post && params[:searchin] && params[:search] != ''
      searchfor = '%' + params[:search].downcase + '%'
      @mark_term = params[:search]
      @search_in = params[:searchin]
      @limit = params[:limit].to_i
			
      # People, Teams and Tips for anyone - not just logged on users
      if @search_in.include?('people')
        @people = Person.find(:all, :conditions => [ 'usertype = 1 AND ((LOWER(login) LIKE ?) or (LOWER(name) LIKE ?) or (LOWER(email) LIKE ?))', searchfor, searchfor, searchfor ], :limit => @limit, :order => 'login')
      end
      
      if @search_in.include?('teams')
        @teams = Team.find(:all, :conditions => [ '(LOWER(name) LIKE ?) or (LOWER(description) LIKE ?)', searchfor, searchfor ], :limit => @limit, :order => 'name')
      end
      
      if @search_in.include?('tips')
        @tips = Tip.find(:all, :conditions => [ '(LOWER(short_description) LIKE ?) or (LOWER(full_description) LIKE ?)', searchfor, searchfor ], :limit => @limit, :order => 'effectiveness desc, id desc')
      end
      
      if @search_in.include?('lists')	
        @lists = List.find_by_sql(["select * from lists where (LOWER(name) LIKE ? or LOWER(description) LIKE ?) and team_id in (select team_id from memberships where confirmed = 1 and person_id = ?) order by name limit ?", searchfor, searchfor, session[:person].id, @limit ])
      end
      
      if @search_in.include?('tasks')
        @person = Person.find(session[:person].id)
        @preference = session[:preference]
        
        begin
          @enable_js = @preference.enable_js
        rescue
          session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
          @enable_js = @preference.enable_js
        end
        
        @tasks = Task.find_by_sql(["select * from tasks where (LOWER(name) LIKE ? or LOWER(description) LIKE ?) and list_id in (select id from lists where team_id in (select team_id from memberships where confirmed = 1 and person_id = ?)) order by next_due asc, name asc limit ?", searchfor, searchfor, @person.id, @limit ])
      end
    
    else
      @mark_term = ''
      @search_in = 'people, teams, tips, lists, tasks'
      @limit = 10
    end
  end
	
	def supporters
	end
	
	def tour
	end
	
	def privacy
	end
	
	def sitemap
		@person = session[:person]
	end
	
	def promotions
		@website = "http://www.mychores.co.uk/"
		
		if session[:person]
			@person = session[:person]
			@website += "?referrer=" + @person.login
			
			@children_count = Person.count(:conditions => ["usertype = 1 AND parent_id = ?", @person.id ])
		end
		
	end
	
	
	def publicity
	
	end


end
