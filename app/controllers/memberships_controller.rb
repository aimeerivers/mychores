class MembershipsController < ApplicationController
  
  before_filter :login_required
  before_filter :find_membership, :only => [:accept, :destroy]
  before_filter :edit_access_required, :only => [:accept]
  before_filter :delete_access_required, :only => [:destroy]
  before_filter :delete_access_required_to_leave, :only => [:leave]
  
  def new
    @invitee = Person.find(params[:person_id])
    @membership = Membership.new(:person => @invitee)
  end
  
  def create
    @membership = Membership.new(params[:membership])
    @membership.person_id = params[:person_id]
    @membership.invited = true
    @membership.confirmed = false
    if @membership.save
      flash[:notice] = 'An invitation will be sent shortly.'
      Email.new_membership_invitation(@membership.person, @membership.team)
      redirect_to(person_path(params[:person_id]))
    else
      render :new
    end
  end
  
  def memrequest
    @membership = Membership.new(params[:membership])
    @membership.person_id = session[:person].id
    @membership.team_id = params[:team_id]
    @membership.requested = true
    @membership.confirmed = false
    if @membership.save
      flash[:notice] = 'Your request to join this team was noted.'
      Email.new_membership_request(@membership.person, @membership.team)
    else
      flash[:notice] = 'Sorry, there was a problem requesting membership.'
    end
    redirect_back
  end
  
  def accept
    @membership.confirmed = true
    @membership.save
    redirect_back
  end
  
  def destroy
    @membership.destroy
    redirect_back
  end
  
  def leave
    Task.assigned_to_person_in_team(@membership.person, @membership.team).each do |task|
      task.rotate = false
      task.person_id = nil
      task.save
    end
    @membership.destroy
    flash[:notice] = 'You have successfully left the team.'
    redirect_back
  end
  
  
  protected
  
  def find_membership
    @membership = Membership.find(params[:id])
  end
  
  def edit_access_required
    if !@membership.editable_by?(session[:person])
      flash[:notice] = "Sorry, you don't have permission to do that."
      redirect_back
    end
  end
  
  def delete_access_required
    if !@membership.deletable_by?(session[:person])
      flash[:notice] = "Sorry, you don't have permission to do that."
      redirect_back
    end
  end
  
  def delete_access_required_to_leave
    @membership = Membership.find_by_team_id_and_person_id(params[:team_id], session[:person].id)
    if !@membership.deletable_by?(session[:person])
      flash[:notice] = "Sorry, you cannot do that."
      redirect_back
    end
  end
  
  
end
