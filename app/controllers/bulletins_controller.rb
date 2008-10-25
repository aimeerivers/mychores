class BulletinsController < ApplicationController

  before_filter :login_required, :except => [:index, :list, :rss]	

	
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @bulletins = Bulletin.paginate(:page => params[:page], :order => 'id desc', :per_page => 5)
  end
  
  
  
  
  def rss
    @rss_title = "MyChores news bulletins"
    @rss_link = "http://www.mychores.co.uk/bulletins"
    @rss_description = "News bulletins at MyChores.co.uk"
    
    @bulletins = Bulletin.find(:all, :limit => 5, :order => "id desc")
    
    render(:layout => false, :content_type => 'application/rss+xml')
  end
  
  

  def new
    if session[:person].status == "Site Creator"
      @bulletin = Bulletin.new
    end
  end

  def create
    @bulletin = Bulletin.new(params[:bulletin])
    if @bulletin.link.empty?
      @bulletin.link = nil
    end
    
    if @bulletin.save
      flash[:notice] = 'Bulletin was successfully created.'
      
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    if session[:person].status == "Site Creator"
      @bulletin = Bulletin.find(params[:id])
    end
  end

  def update
    @bulletin = Bulletin.find(params[:id])
    
    if @bulletin.update_attributes(params[:bulletin])

      if @bulletin.link.empty?
        @bulletin.link = nil
        @bulletin.save
      end
      
      flash[:notice] = 'Bulletin was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  
end
