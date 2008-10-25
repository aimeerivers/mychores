class TestimonialsController < ApplicationController

  before_filter :login_required, :only => [:edit, :update]
  
  def index
    redirect_to :action => 'list'
  end
  
  def list
    @testimonials = Testimonial.find(:all, :conditions => "approved = 1", :order => "id desc")
    
    unless session[:person].nil?
      if session[:person].status == "Site Creator"
        @editaccess = true
      else
        @editaccess = false
      end
    end
    
  end
  
  
  def new
    @testimonial = Testimonial.new
    
    unless session[:person].nil?
      @testimonial.name = session[:person].name
      @testimonial.login_id = session[:person].login
    end
  end

  def create
    @testimonial = Testimonial.new(params[:testimonial])
	if validate_recap(params, @testimonial.errors) && @testimonial.save
	   flash[:notice] = 'Thank you. Your testimonial will appear here once approved.'
	   
	      @email = Email.new
	      @email.subject = "New MyChores testimonial from " + @testimonial.name + " (" + @testimonial.login_id + ")"
          @email.message = @testimonial.message
          
          @email.message += "
          
Approve it here: "

          @email.message += "http://www.mychores.co.uk/testimonials/edit/" + @testimonial.id.to_s
          
          @email.to = "contact@mychores.co.uk"
          @email.save
	   
	   redirect_to :action => 'list'
	else
	   render :action => 'new'
	end
  end
  
  def edit
    if session[:person].status == "Site Creator"
    	@testimonial = Testimonial.find(params[:id])
    end
  end

  def update
    @testimonial = Testimonial.find(params[:id])
    if session[:person].status == "Site Creator"
	    if @testimonial.update_attributes(params[:testimonial])
	      flash[:notice] = 'Testimonial was successfully updated.'
	      redirect_to :action => 'list'
	    else
	      render :action => 'edit'
	    end
    end
  end
  
  
end
