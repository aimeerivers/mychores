class StatisticsController < ApplicationController
  
  
  def index
  
    # To change the minimum all you need to do is fix this number
    minimum_people_in_timezone = 15
    
    if session[:person].nil?
      @timenow = Time.now
    else
      @person = Person.find(session[:person].id)
      @mytimezone = TimeZone.new(@person.timezone_name)
      @timenow = Time.parse(@mytimezone.now().to_s)
    end
    
    
    @completions = []
    @months = [] 
    
    i = 12
    loop do
      @completions[i] = Completion.count(:conditions => [ "MONTH(date_completed) = MONTH(?) and YEAR(date_completed) = YEAR(?)" , @timenow.months_ago(i), @timenow.months_ago(i) ] )
      @months[i] = (@timenow.months_ago(i)).localize("%b")
      i -= 1
      break if i < 0
    end
    
    max = @completions.max
    
    @completions_chart = GoogleChart.new
    @completions_chart.type = :bar_vertical_stacked
    @completions_chart.data = @completions.reverse
    @completions_chart.labels = @months.reverse
    @completions_chart.y_labels = [0, max]
    @completions_chart.max_data_value = max
    @completions_chart.width = 400
    @completions_chart.height = 180
    @completions_chart.colors = '60abf1'
    @completions_chart.title = "Tasks completed by month"
    
    
    @days_in_month = ::Time.days_in_month(@timenow.month.to_i, @timenow.year.to_i)
    @day_today = @timenow.mday
    
    @average_tasks_per_day = @completions[0].to_f / @day_today
    @projected_tasks_this_month = @average_tasks_per_day * @days_in_month
    
    
    
    
    
    @thirty_day_totals = []
    
    i = 27
    loop do
      @thirty_day_totals[i] = Completion.count(:conditions => [ "date_completed = ?", @timenow.advance(:days => -i).strftime("%Y-%m-%d") ] )
      i -= 1
      break if i < 0
    end
    
    max = @thirty_day_totals.max
    
    thirty_day_labels = []
    thirty_day_labels[0] = @timenow.advance(:days => -28).localize("%e %b")
    thirty_day_labels[1] = @timenow.advance(:days => -21).localize("%e %b")
    thirty_day_labels[2] = @timenow.advance(:days => -14).localize("%e %b")
    thirty_day_labels[3] = @timenow.advance(:days => -7).localize("%e %b")
    thirty_day_labels[4] = @timenow.localize("%e %b")
    
    
    @thirty_day_chart = GoogleChart.new
    @thirty_day_chart.type = :line
    @thirty_day_chart.line_style = "2,2,1"
    @thirty_day_chart.data = @thirty_day_totals.reverse
    @thirty_day_chart.marker = "B,E6F2FA,0,0,0"
    @thirty_day_chart.labels = thirty_day_labels
    @thirty_day_chart.y_labels = ["", max]
    @thirty_day_chart.max_data_value = max
    @thirty_day_chart.width = 400
    @thirty_day_chart.height = 180
    @thirty_day_chart.colors = '0077CC'
    @thirty_day_chart.title = "Tasks completed in the last 28 days"
    
    
    
    
    
    
    
    
    @people_by_timezone = Person.find_by_sql(["SELECT timezone_name, count(*) AS counter FROM people WHERE usertype = 1 GROUP BY timezone_name HAVING counter >= ? ORDER BY counter DESC, timezone_name ASC;", minimum_people_in_timezone])

    @people_count = 0
    @maximum_timezones = 0
    
    @timezone_data = []
    @timezone_labels = []
    
    for timezone in @people_by_timezone
      @people_count += timezone.counter.to_i
      if timezone.counter.to_i > @maximum_timezones
        @maximum_timezones = timezone.counter.to_i
      end
      @timezone_data << timezone.counter
      @timezone_labels << timezone.timezone_name + ": " + timezone.counter.to_s
    end
    
    
    @total_people = Person.count(:conditions => "usertype = 1")
    @other_timezones = @total_people - @people_count
    @timezone_data << @other_timezones
    @timezone_labels << "All others: " + @other_timezones.to_s
    
    if @other_timezones > @maximum_timezones
      @maximum_timezones = @other_timezones
    end
    
    
    
    @timezone_chart = GoogleChart.new
    @timezone_chart.type = :pie_3d
    @timezone_chart.data = @timezone_data
    @timezone_chart.max_data_value = @maximum_timezones
    @timezone_chart.labels = @timezone_labels
    @timezone_chart.width = 600
    @timezone_chart.height = 180
    @timezone_chart.colors = '0077CC'
    @timezone_chart.title = "People by location"
    
    
    
    
  end
	
	def monthly
		if params[:year]
			@current_year = params[:year]
		else
			@current_year = "2007"
		end
			
		if params[:month]
			@current_month = params[:month]
		else
			@current_month = "3"
		end
	end
	
	def league
		@topten = Completion.find_by_sql("SELECT task.name as Task, count(completion.date_completed) as Count, count(distinct(completion.person_id)) as People, count(completion.date_completed) * count(distinct(completion.person_id)) as Score FROM tasks task, completions completion where completion.task_id = task.id group by task.name order by Score desc, Task ASC limit 10")
	
	end
  
  

  def theme
    if params[:id]
      @themename = params[:id]
    else
      @themename = 'Hill'
    end
    
    @number_of_people = Preference.count_by_sql(["SELECT count( * ) FROM preferences pr, people p WHERE pr.person_id = p.id AND p.usertype = 1 and pr.theme = ?", @themename.downcase])
    
    render :layout => false
  end
  
end
