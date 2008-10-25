class TipsController < ApplicationController

  before_filter :login_required, :except => [:index, :list, :show, :rss, :tagcloud]	

	
  def index
    list
    render(:action => 'list')
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
  
    if params[:person]
      @submitted_by = Person.find_by_login(params[:person])
      if params[:popular]
        @tips = Tip.paginate(:page => params[:page], :conditions => "person_id = " + @submitted_by.id.to_s + " and is_anon = false", :order => 'effectiveness desc, id desc', :per_page => 10)
        # @tip_pages, @tips = paginate :tips, :per_page => 10, :order => "effectiveness desc, id desc", :conditions => "person_id = " + @submitted_by.id.to_s + " and is_anon = false"
      else
        @tips = Tip.paginate(:page => params[:page], :conditions => "person_id = " + @submitted_by.id.to_s + " and is_anon = false", :order => 'id desc', :per_page => 10)
        # @tip_pages, @tips = paginate :tips, :per_page => 10, :order => "id desc", :conditions => "person_id = " + @submitted_by.id.to_s + " and is_anon = false"
      end
      
    elsif params[:tag]
      @cgi_escaped = CGI::escape(params[:tag])
      if params[:recent]
        @tips = Tip.paginate(:page => params[:page], :conditions => "cached_tag_list like '%" + params[:tag] + "%'", :order => 'id desc', :per_page => 10)
        # @tip_pages, @tips = paginate :tips, :per_page => 10, :order => "id desc", :conditions => "cached_tag_list like '%" + params[:tag] + "%'"
      else
        @tips = Tip.paginate(:page => params[:page], :conditions => "cached_tag_list like '%" + params[:tag] + "%'", :order => 'effectiveness desc, id desc', :per_page => 10)
        # @tip_pages, @tips = paginate :tips, :per_page => 10, :order => "effectiveness desc, id desc", :conditions => "cached_tag_list like '%" + params[:tag] + "%'"
      end
      
    else
      if params[:recent]
        @tips = Tip.paginate(:page => params[:page], :order => 'id desc', :per_page => 10)
        # @tip_pages, @tips = paginate :tips, :per_page => 10, :order => "id desc"
      else
        @tips = Tip.paginate(:page => params[:page], :order => 'effectiveness desc, id desc', :per_page => 10)
        # @tip_pages, @tips = paginate :tips, :per_page => 10, :order => "effectiveness desc, id desc"
      end
    end
  end
  
  
  
  
  def rss
    @rss_title = "MyChores tips"
    @rss_link = "http://www.mychores.co.uk/tips"
    @rss_description = "Cleaning tips at MyChores.co.uk"
    
    if params[:person]
      
      @submitted_by = Person.find_by_login(params[:person])
      
      @rss_title += " submitted by " + params[:person]
      @rss_link += "?person=" + params[:person]
      @rss_description += " submitted by " + @submitted_by.name
      
      @tips = Tip.find(:all, :limit => 10, :order => "id desc", :conditions => "person_id = " + @submitted_by.id.to_s + " and is_anon = false")

    elsif params[:tag]
      
      @rss_title += " by tag: " + params[:tag]
      @rss_link += "?tag=" + CGI::escape(params[:tag])
      @rss_description += " by tag: " + params[:tag]
      
      @tips = Tip.find(:all, :limit => 10, :order => "id desc", :conditions => "cached_tag_list like '%" + params[:tag] + "%'")
      
    else
      @tips = Tip.find(:all, :limit => 10, :order => "id desc")
    end
    
    render(:layout => false, :content_type => 'application/rss+xml')
  end
  
  
  
  def tagcloud
    require 'cgi'
    
    @tag_counts = Tip.tag_counts(:order => 'name asc')
    
    maximum = 1
    minimum = 100
    
    for tag in @tag_counts do
      if tag.count > maximum
        maximum = tag.count
      end
      if tag.count < minimum
        minimum = tag.count
      end
    end
    
    @delta = (maximum - minimum)/8.0

    @thresholds = []
    
    for i in 1..8
      @thresholds[i] = minimum + i * @delta
    end

  end

  def show
    @tip = Tip.find(params[:id])
    
    unless params[:s]
      @tip.effectiveness += 1 # One point just for being opened
      @tip.save
    end
    
    @previous_tip = Tip.find(:first, :order => "id desc", :conditions => "id < " + @tip.id.to_s)
    @next_tip = Tip.find(:first, :order => "id asc", :conditions => "id > " + @tip.id.to_s)
  end

  def new
    @tip = Tip.new
  end

  def create
    @tip = Tip.new(params[:tip])
    @tip.person_id = session[:person].id
    
    if @tip.tag_edit.empty?
      @tip.tag_list = "no tags"
    else
      @tip.tag_list = @tip.tag_edit
    end
    
    if @tip.save
      flash[:notice] = 'Tip was successfully created.'
      
      redirect_to :action => 'show', :id => @tip.id, 's' => '1'
    else
      render :action => 'new'
    end
  end

  def edit
    @tip = Tip.find(params[:id])
  end

  def update
    @tip = Tip.find(params[:id])
    
    if @tip.update_attributes(params[:tip])
    
      if @tip.tag_edit.empty?
        @tip.tag_list = "no tags"
      else
        @tip.tag_list = @tip.tag_edit
      end
      @tip.save
      
      flash[:notice] = 'Tip was successfully updated.'
      redirect_to :action => 'show', :id => @tip.id, 's' => '1'
    else
      render :action => 'edit'
    end
  end

  def destroy_tip
    @tip = Tip.find(params[:id])
    
    if @tip.person_id == session[:person].id or session[:person].status == "Site Creator"
    
      @tip.tag_list.remove(@tip.cached_tag_list)
      @tip.save
      
      if @tip.destroy
        flash[:notice] = 'Tip was successfully deleted.'
      else
        flash[:notice] = 'Could not delete the requested tip.'
      end
      
    else
      flash[:notice] = 'You do not have permission to delete that tip.'
    end
    
    redirect_to :action => 'list'
  end
  
  
  
  def useful
    @tip = Tip.find(params[:id])
    
    if session[:person].id == @tip.person_id
      flash[:notice] = 'You may not give feedback for your own tips - sorry!'
    else
      @tip.effectiveness += 5
      @tip.save
      flash[:notice] = 'Feedback recorded: good tip.'
    end
    
    redirect_to :action => 'show', :id => @tip.id, 's' => '1'
  end
  
  
  
  def not_useful
    @tip = Tip.find(params[:id])
    
    if session[:person].id == @tip.person_id
      flash[:notice] = 'You may not give feedback for your own tips - sorry!'
    else
      @tip.effectiveness -= 5
      @tip.save
      flash[:notice] = 'Feedback recorded: bad tip.'
    end
    
    redirect_to :action => 'show', :id => @tip.id, 's' => '1'
  end
  
end
