class PeopleController < ApplicationController

  before_filter :login_required, :except => [:show, :show_by_login]
  
  def index
    redirect_to :controller => 'tasks', :action => 'workload'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :update ],
         :redirect_to => { :action => :list }

  def list
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def show
    @person = Person.find(params[:id])
    @memberships = Membership.find(:all, :conditions => ["person_id = ?", @person.id])
    
    @person_tips = Tip.find(:all, :limit => 3, :order => "id desc", :conditions => "person_id = " + @person.id.to_s + " and is_anon = false")
    @number_of_tips = Tip.count(:conditions => "person_id = " + @person.id.to_s + " and is_anon = false")
  end

	def show_by_login
		@person = Person.find_by_login(params[:login])
		unless @person.nil?
			@memberships = Membership.find(:all, :conditions => ["person_id = ?", @person.id])
			
			@person_tips = Tip.find(:all, :limit => 3, :order => "id desc", :conditions => "person_id = " + @person.id.to_s + " and is_anon = false")
			@number_of_tips = Tip.count(:conditions => "person_id = " + @person.id.to_s + " and is_anon = false")
			render :action => 'show', :id => @person.id
		end
	end

  def edit
    @person = Person.find_by_login(params[:id])
  end

  def update
    return unless session[:person].status == "Site Creator"
    @person = Person.find(params[:id])
    if @person.update_attributes(params[:person])
      @person.email_verified = params[:person][:email_verified]
      @person.status = (params[:person][:status].blank?) ? nil : params[:person][:status]
      @person.save
    	flash[:notice] = "Person details updated."
      redirect_to :action => 'show', :id => @person
    else
      render :action => 'edit'
    end
  end
  
  
	
	def referrals
		@person = session[:person]
		@parent = @person.parent
		
		@children = Person.find(:all, :conditions => [ "usertype = 1 AND parent_id = ?", @person.id], :order => 'login')
		@children_count = Person.count(:conditions => ["usertype = 1 AND parent_id = ?", @person.id ])
		
		@grandchildren = Person.find(:all, :conditions => [ "usertype = 1 AND parent_id in (select id from people where usertype = 1 AND parent_id = ?)", @person.id], :order => 'login')
		@grandchildren_count = Person.count(:conditions => ["usertype = 1 AND parent_id in (select id from people where usertype = 1 AND parent_id = ?)", @person.id ])	
	end
	
	
	
	
  
#	def updateall
		# useful for adding in some controlled fields, eg the emergency code.
		# should not be available all the time.
#		@people = Person.find(:all)
#		for person in @people
#			person.save
#		end
#		flash[:notice] = "All people updated." 
#		redirect_to :controller => 'tasks', :action => 'workload'
#	end


	
end
