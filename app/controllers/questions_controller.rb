class QuestionsController < ApplicationController

	before_filter :login_required, :except => [:show, :list, :index]
	
  def index
    list
    render :action => 'list'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @questions = Question.find(:all, :order => 'displayorder')
  end

  def show
    @question = Question.find(params[:id])
  end

  def new
    @question = Question.new
  end

  def create
    @question = Question.new(params[:question])
    if session[:person].status == "Site Creator"
	    if @question.save
	      flash[:notice] = 'Question was successfully created.'
	      redirect_to :action => 'list'
	    else
	      render :action => 'new'
	    end
	 end
  end

  def edit
    if session[:person].status == "Site Creator"
    	@question = Question.find(params[:id])
    end
  end

  def update
    @question = Question.find(params[:id])
    if session[:person].status == "Site Creator"
	    if @question.update_attributes(params[:question])
	      flash[:notice] = 'Question was successfully updated.'
	      redirect_to :action => 'list'
	    else
	      render :action => 'edit'
	    end
    end
  end
  
  
end
