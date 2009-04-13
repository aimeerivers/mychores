class TestimonialsController < ApplicationController

  before_filter :admin_authorised, :only => [:edit, :update]
  
  # GET /testimonials
  def index
    @testimonials = Testimonial.approved
  end
  
  # GET /testimonials/new
  def new
    @testimonial = Testimonial.new
    if logged_in?
      @testimonial.name = session[:person].name
      @testimonial.login_id = session[:person].login
    end
  end

  # POST /testimonials
  def create
    @testimonial = Testimonial.new(params[:testimonial])
    if recaptcha_valid?(params, @testimonial)
      if @testimonial.save
        flash[:notice] = 'Thank you. Your testimonial will appear here once approved.'
        @email = Email.new
        @email.to = "contact@mychores.co.uk"
        @email.subject = "New MyChores testimonial from #{@testimonial.name} (#{@testimonial.login_id})"
        @email.message = "#{@testimonial.message}\n\nApprove it here: #{edit_testimonial_url(@testimonial)}"
        @email.save
        redirect_to(testimonials_path)
      else
        render :action => 'new'
      end
    end
  end
  
  # GET /testimonials/1/edit
  def edit
    @testimonial = Testimonial.find(params[:id])
  end

  # PUT /testimonials/1
  def update
    @testimonial = Testimonial.find(params[:id])
    if @testimonial.update_attributes(params[:testimonial])
      flash[:notice] = 'Testimonial was successfully updated.'
      redirect_to testimonials_path
    else
      render :action => 'edit'
    end
  end

  protected

  def recaptcha_valid?(params, testimonial)
    return true if %w(development test).include?(RAILS_ENV)
    validate_recap(params, testimonial.errors)
  end  
  
end
