class MessagesController < ApplicationController
  def index
    redirect_to :action => 'new'
  end

  def new
    @message = Message.new
    unless session[:person].nil?
    	@message.name = session[:person].name
    	@message.email = session[:person].email
    end
  end

  def create
    @message = Message.new(params[:message])
    if validate_recap(params, @message.errors) && @message.save
    	Notifier::deliver_contact_message(@message)
      flash[:notice] = 'Thank you, your message was sent.'
      redirect_to :controller => 'home', :action => 'welcome'
    else
      render :action => 'new'
    end
  end
end
