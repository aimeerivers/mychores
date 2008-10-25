class NewslettersController < ApplicationController

	before_filter :login_required
	
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :do_send ],
         :redirect_to => { :action => :list }

  def list
    if session[:person].status == 'Site Creator'
      @total_wanting = Person.count_by_sql(["select count(*) from people where usertype = 1 and email_verified = true and newsletters = true"])
      @newsletter_pages, @newsletters = paginate(:newsletters, :per_page => 5, :order => "id desc")
    end
  end

  def new
    if session[:person].status == 'Site Creator'
      @newsletter = Newsletter.new
    end
  end

  def create
    if session[:person].status == 'Site Creator'
      @newsletter = Newsletter.new(params[:newsletter])
       if @newsletter.save
        flash[:notice] = 'Newsletter was saved.'
        redirect_to :action => 'list'
      else
        render :action => 'new'
      end
    end
  end
  
  
  def show
    if session[:person].status == 'Site Creator'
      @newsletter = Newsletter.find(params[:id])
    end
  end
  
  
  def send_newsletter
    if session[:person].status == 'Site Creator'
      @newsletter = Newsletter.find(params[:id])
    end
  end
  
  
  def do_send
    if session[:person].status == 'Site Creator'
    
      @person = Person.find(session[:person].id)
      @mytimezone = TimeZone.new(@person.timezone_name)
      @timenow = @mytimezone.now()
    
      @newsletter = Newsletter.find(params[:id])
      @send_from = params[:send_from].to_i
      @send_to = params[:send_to].to_i
      
      if @send_to >= @send_from
      
        @number_to_send = @send_to - @send_from + 1
        @send_start = @send_from - 1
        
      
        if @newsletter.details.nil?
          @newsletter.details = ""
        end
        @newsletter.details += " 
"
        @newsletter.details += @timenow.to_s
        @newsletter.details += ": " + @send_from.to_s + " - " + @send_to.to_s
        @newsletter.save
        
      
        
        @people = Person.find_by_sql(["select * from people where usertype = 1 and email_verified = true and newsletters = true limit ?,?", @send_start, @number_to_send])
        for person in @people
          Notifier::deliver_newsletter(person, @newsletter)
        end

        flash[:notice] = 'Newsletter was sent to ' + @people.size.to_s + ' people.'
      end
      
      redirect_to :action => 'list'
    end
  end
  
end
