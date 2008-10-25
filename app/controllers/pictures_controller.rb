class PicturesController < ApplicationController

before_filter :login_required

  def index
    @person = session[:person]
    @mypictures = Picture.paginate(:page => params[:page], :conditions => [ "person_id = ?", session[:person].id ], :order => 'created_on desc', :per_page => 9)
  end
  
  
  
   # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :flickr_import ],
         :redirect_to => { :controller => 'home', :action => :index}
  

  def show
    @picture = Picture.find params[:id]
    @tasks = Task.find_by_sql ["select * from tasks where picture_id = ? and list_id in (select id from lists where team_id in (select id from teams where id in (select team_id from memberships where person_id = ? and confirmed = 1))) order by next_due ASC, list_id ASC, name ASC", @picture.id, session[:person].id]
  end
  
  
  

  def new
    @person = Person.find(session[:person].id)
    @picturecount = Picture.count(:conditions => [ 'person_id = ?', @person.id] )
    
    if @person.status == "" or @person.status.nil?
      @is_supporter = false
    else
      @is_supporter = true
    end
    
    @picture = Picture.new
    
    if params[:task]
      # Is it one of their tasks?
      @task = Task.find(params[:task])
      @list = List.find(@task.list_id)
      @team = Team.find(@list.team_id)
      
      @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", session[:person].id, @task.list.team.id ])
	  if @membership_search.nil?
        @task = nil
      end
    end
    
  end
  
  
  
  
  

  def create
    @picture = Picture.new(params[:picture])
    @person = session[:person]
    @picture.person_id = @person.id # uploaded by

    if @picture.save
    
      flash[:notice] = "Your picture was successfully uploaded."
    
      if params[:task]
        # Immediately attach this picture to the task
        @task = Task.find(params[:task])
		
		# Check that they're actually allowed to update that task!
		@membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", session[:person].id, @task.list.team.id ])
		unless @membership_search.nil?
		  @task.picture_id = @picture.id
		  @task.save
		  redirect_to :controller => 'tasks', :action => 'show', :id => @task.id
		else
		  # They tried to attach to a task which wasn't theirs
		  redirect_to :action => 'index'
		end
		
      else
        redirect_to :action => 'index'
      end
      
    else
      # There was something wrong with the upload
      flash[:notice] = "Either you uploaded an invalid picture format, or the picture is too big. Please try again."
      redirect_to :action => 'new'
    
    end
  end
  
  
  def choose
    @task = Task.find(params[:task])
    @list = List.find(@task.list_id)
    @team = Team.find(@list.team_id)
    
    @person = session[:person]
    @mypictures = Picture.find(:all, :conditions => ["person_id = ? ", @person.id], :order => 'created_on desc')
    
    @teampictures = Picture.find_by_sql([ "select * from pictures where is_public = false and id != 1 and id in (select picture_id from tasks where list_id in (select id from lists where team_id in (select team_id from memberships where confirmed = 1 and person_id = ? )))", session[:person].id ])
    
    @publicpictures = Picture.find(:all, :conditions => "is_public = true", :order => 'filename asc')
  end
  
  
  
  
  
  
  
  
  
  
  def flickr_import
  
    @person = Person.find(session[:person].id)
	@preference = Preference.find(:first, :conditions => ["person_id = ?", session[:person].id ])
    
    
    size_required = 'Small'
    @flickr_email = params[:preference][:flickr_email]
    @flickr_tag = params[:preference][:flickr_tag]
    
    @preference.flickr_email = @flickr_email
    @preference.flickr_tag = @flickr_tag
    @preference.save
    
    @number_imported = 0
    @error_message = nil
      
    require 'flickr-1.0.0-with-key/flickr.rb'
    
    begin
      flickr = Flickr.new
      user = flickr.users(@flickr_email)
    rescue
      @error_message = "Email address not found on Flickr"
    end
    
    
    
    
    begin
    
      unless @flickr_tag.empty? or @flickr_tag.nil?
        @photos = user.tag(@flickr_tag)
      else
        @photos = user.photos
      end
      
    rescue
      @error_message = "No photos found on Flickr for that email/tag"
    end
    
    
    begin
      
      unless @photos.nil?
      
      
        for photo in @photos
        
          if @number_imported < 20
          
            # Check if the photo has already been imported
            @checkphoto = Picture.find(:first, :conditions => ['is_flickr_import = true and filename = ? and person_id = ?', photo.filename, @person.id])
            
            if @checkphoto.nil?
              # Then create this one as a new picture.
              
          
              @picture = Picture.new
              
              @picture.person_id = @person.id # uploaded by
        
              @picture.content_type = 'image/jpeg'
              @picture.filename = photo.filename
              
              
              @picture.size = 160 # FIX THIS?!!!
      
              size = photo.sizes(size_required)
              @picture.width = size['width']
              @picture.height = size['height']
              
              @picture.is_flickr_import = true
              @picture.flickr_url = photo.url
              
              @picture.save
              
              directory = "public/pictures/" + ("%08d" % @picture.id).scan(/..../).join("/")
              
              Dir.mkdir(directory) unless File.directory?(directory)
              
              File.open(directory + "/" + photo.filename, 'w') do |f|
                f.puts photo.file(size_required)
              end
              
              @number_imported += 1
              
              
            end # Created new photo
            
          end # Already got 20
        
        end # finished iterating through photos
        
      end # No photos found
      
    rescue
      # Something went wrong
      @error_message = "Photos could not be copied to MyChores"
    end
    
    render(:layout => false)
    
  end
  
  
  
  
  
  
  
  def resize
    @picture = Picture.find params[:id]
    
    if @picture.person_id == session[:person].id
    
      if @picture.orientation == 'landscape'
        @picture.orientation = 'portrait'
      else
        @picture.orientation = 'landscape'
      end
      @picture.save
  	  flash[:notice] = "Picture re-sized. If you don't like it, you can change it back again."
      redirect_to :action => 'show', :id => @picture.id
      
    else
  	  flash[:notice] = "You do not have permission to re-size this picture."
      redirect_to :action => 'show', :id => @picture.id
    end
  end
  
  
  def destroy
    @picture = Picture.find(params[:id])
    
    if @picture.person_id == session[:person].id
    
        # Find any tasks using this picture
        @tasks = Task.find_all_by_picture_id(@picture.id)
        @tasks = Task.find(:all, :conditions => ["picture_id = ?", @picture.id])
        for task in @tasks
          task.picture_id = nil
          task.save
        end
        
	 	@picture.destroy
	 	
	 	
	 	flash[:notice] = "Your picture was deleted successfully."
        redirect_to :action => 'index'
        
    else
      flash[:notice] = "You cannot delete this picture because you did not upload it."
      redirect_to :action => 'show', :id => @picture.id
    end
  end
  
end
