require "pathname"
require "cgi"

# load the openid library
require "openid"
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

class OpenidController < ApplicationController

  
  before_filter :login_required, :only => [:associate, :disassociate]
  
  
  
  
  # process the login request, disover the openid server, and
  # then redirect.
  def login
    openid_url = params[:openid_url]

    if openid_url=="" 
      flash[:notice] = "No OpenID URL was given." 
    elsif (request.post?)
    
      begin
        request = consumer.begin(openid_url)      
      rescue OpenID::OpenIDError => e
        flash[:notice] = "Could not find OpenID server for #{openid_url}"
        redirect_to :action => 'login'
        return
      end

      return_to = url_for(:action=> 'complete')
      trust_root = url_for(:controller=>'')

      url = request.redirect_url(trust_root, return_to)
      redirect_to(url)    
    end    

  end
  
  
  
  
  
  
  def register
    # Actually the same as login but it looks a bit different
    openid_url = params[:openid_url]

    if openid_url=="" 
      flash[:notice] = "No OpenID URL was given." 
    elsif (request.post?)
    
      begin
        request = consumer.begin(openid_url)
      rescue OpenID::OpenIDError => e
        flash[:notice] = "Could not find OpenID server for #{openid_url}"
        redirect_to :action => 'login'
        return
      end

      # request.add_extension_arg('sreg', 'optional', 'nickname,fullname,email')
      sreg_request = OpenID::SReg::Request.new
      sreg_request.request_fields(['nickname', 'fullname', 'email'], false) # optional
      sreg_request.policy_url = "http://www.mychores.co.uk/home/privacy"
      request.add_extension(sreg_request)
      
      return_to = url_for(:action=> 'complete')
      trust_root = url_for(:controller=>'')

      url = request.redirect_url(trust_root, return_to)
      redirect_to(url)  
        
    end    

  end
  
  
  
  
  

  # handle the openid server response
  def complete
    current_url = url_for(:action => 'complete', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}
    response = consumer.complete(parameters, current_url)
    
    case response.status
    when OpenID::Consumer::SUCCESS
    
      if session[:person].nil?
        # Nobody is currently logged on so either register or login

        @user = Person.find_by_openid_url(response.endpoint.claimed_id)
        
        if @user.nil?
          # New user - get a few more details
          session[:openid_url] = response.endpoint.claimed_id
          # session[:extra_info] = response.extension_response('sreg')
          sreg_resp = OpenID::SReg::Response.from_success_response(response)
          
          session[:extra_info] = sreg_resp.data
          
          flash[:notice] = "Your OpenID has been verified. Please enter a few more details to complete your registration."
          redirect_to :action => 'complete_registration'
          
        else
          # Login
          session[:person] = @user
          
          # Get their preferences loaded too
          session[:preference] = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
          
          flash[:notice]  = "You are now logged in."
          redirect_back_or_default :controller => 'home', :action => 'index'
        end
        
      else
        # Somebody is logged on and wants to associate their account
        
        @person = Person.find_by_id(session[:person])
        
        # Check if anyone is using that OpenID already
        @user = Person.find_by_openid_url(response.endpoint.claimed_id)
        
        if @user.nil?
          # Okay, can associate it with the logged on user.
          @person.openid_url = response.endpoint.claimed_id
          @person.save
          
          flash[:notice]  = "Your account has been successfully associated with an OpenID."
          redirect_to :action => 'associate'
          
        else
          flash[:notice]  = "Sorry, that OpenID has already been claimed."
          redirect_to :action => 'associate'
        end
        
      end
      
      return

    when OpenID::Consumer::FAILURE
      if response.endpoint.claimed_id
        flash[:notice] = "Verification of #{response.endpoint.claimed_id} failed."

      else
        flash[:notice] = 'Verification failed.'
      end

    when OpenID::Consumer::CANCEL
      flash[:notice] = 'OpenID validation cancelled or denied.'

    else
      flash[:notice] = 'Unknown response from OpenID server.'
    end
  
    redirect_to :action => 'login'
  end
  
  
  

  
	def complete_registration
		@person = Person.new(params[:person])
		
		if session[:openid_url].nil?
		  flash[:notice]  = "Sorry, your OpenID url was not verified."
		  redirect_to(:action => 'register')
		  return
		end
		
		unless session[:extra_info].nil? # Doesn't work for, eg, typekey.com
    		# Pull through any information supplied by OpenID
    		@person.login = session[:extra_info]["nickname"] if @person.login.nil?
    		@person.name = session[:extra_info]["fullname"] if @person.name.nil?
    		@person.email = session[:extra_info]["email"] if @person.email.nil?
    		session[:extra_info] = nil
		end
		
		@person.openid_url = session[:openid_url]
		
		# Make up a random password for them
		@person.password = Person.sha1(Time.now.to_s) if @person.password.nil?
		@person.password_confirmation = @person.password
		
		# Fill in the validation (if they've got this far they're valid!)
		#@person.validation = "H6a38G"
		
		
		unless session[:code].nil?
			@invitation = Invitation.find(:first, :conditions => [ "code = ? and accepted = 0", session[:code] ])
			unless @invitation.nil?
				session[:email] = @invitation.email
				session[:referrer] = @invitation.person.login
			end
		end
		
		
		
	 

    if request.post? and @person.save

      session[:person] = @person

      @person.create_preference_record
      session[:preference] = @person.preference
    
      auto = @person.signup_new_user(session[:code])
      # Includes creating standard tasks and sending emails
      
      
      if auto == 1
        redirect_to :controller => 'admin', :action => 'welcome', :auto => 1
      else
        redirect_to :controller => 'admin', :action => 'welcome'
      end
      
    end      
  end  
  
  
  
  
  
  def associate
    @person = Person.find_by_id(session[:person].id)
    
    openid_url = params[:openid_url]

    if openid_url=="" 
      flash[:notice] = "No OpenID URL was given." 
    elsif (request.post?)
    
    
      begin
        request = consumer.begin(openid_url)      
      rescue OpenID::OpenIDError => e
        flash[:notice] = "Could not find OpenID server for #{openid_url}"
        redirect_to :action => 'login'
        return
      end
      
      return_to = url_for(:action=> 'complete')
      trust_root = url_for(:controller=>'')

      url = request.redirect_url(trust_root, return_to)
      redirect_to(url) 
          
    end    
  end
  
  
  
  def disassociate
    @person = Person.find_by_id(session[:person].id)
    
    @person.openid_url = nil
    @person.save
    
    redirect_to :action => 'associate'
    
  end
  
  
  
  

  private

  # Get the OpenID::Consumer object.
  def consumer
    # create the OpenID store for storing associations and nonces,
    # putting it in your app's db directory
    store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
    store = OpenID::Store::Filesystem.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end

  # get the logged in user object
  def find_user
    return nil if session[:user_id].nil?
    User.find(session[:user_id])
  end
  
end
