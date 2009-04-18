class MembershipsController < ApplicationController

  def memrequest
    if params[:team]
      @team = Team.find(params[:team])
      @person = session[:person]
      validitykey = Person.sha1(@person.name + Time.now.to_s)

      @membership = Membership.new(:team_id => @team.id, :person_id => @person.id, :requested => 1, :confirmed => 0, :validity_key => validitykey)
      @membership.save

      flash[:notice] = 'Your request to join this team was noted.'
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id

      # Notifier::deliver_memrequest(@team, @person)

      # Send an email
      @email = Email.new
      @email.subject = "New membership request from mychores.co.uk"
      @email.message = "Dear " + @team.owner_name + ",

      " + @person.name + " (" + @person.login + ") has asked to join your team: " + @team.name + ".

Log into MyChores to view their profile and accept or decline this request. You'll find the links when you log in.

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
      @email.to = @team.owner_email
      @email.save
    end
  end

  def invite
    @invitee = Person.find(params[:person])
  end

  def meminvite
    if params[:team] && params[:person]
      @team = Team.find(params[:team])
      @person = Person.find(params[:person])

      @check = Membership.find(:first, :conditions => [ "person_id = ? AND team_id = ?", @person.id, @team.id])

      if @check.nil?
        validitykey = Person.sha1(@person.name + Time.now.to_s)

        @membership = Membership.new(:team_id => @team.id, :person_id => @person.id, :invited => 1, :confirmed => 0, :validity_key => validitykey)
        @membership.save

        flash[:notice] = 'An invitation will be sent shortly.'

        # Notifier::deliver_meminvite(@team, @person)

        # Send an email
        @email = Email.new
        @email.subject = "New membership invitation from mychores.co.uk"
        @email.message = "Dear " + @person.name + ",

You have been invited to join a team: " + @team.name + ".

Log into MyChores to accept or decline this invitation. You'll find the links when you log in.

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
        @email.to = @person.email
        @email.save

      else
        flash[:notice] = 'Invitation not saved. Either the person is already a member, or an invitation has already been sent.'
      end
      redirect_to :controller => 'people', :action => 'show', :id => @person.id
    end
  end

  def memaccept
    @membership = Membership.find(params[:id])
    if @membership.validity_key == params[:key]
      @membership.confirmed = 1
      @membership.save
      flash[:notice] = 'Membership successfully updated.'
    else
      flash[:notice] = 'Error: validity check failed. Membership details not updated.'
    end
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def memdecline
    @membership = Membership.find(params[:id])
    if @membership.validity_key == params[:key]
      @membership.destroy
      flash[:notice] = 'Membership declined.'
    else
      flash[:notice] = 'Error: validity check failed. Membership details not updated.'
    end
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def index
    redirect_to :controller => 'tasks', :action => 'workload'
  end

  def list
    redirect_to :controller => 'tasks', :action => 'workload'
  end



  def remove
    @membership = Membership.find(params[:id])

    @person = @membership.person
    @team = @membership.team

    if params[:returnto] then
      returnto = params[:returnto]
    else
      returnto = "team"
    end

    allowedtodelete = false

    if @person.id == session[:person].id then
      allowedtodelete = true # allowed to remove yourself from a team
    elsif @team.person.id == session[:person].id then
      allowedtodelete = true # allowed to remove someone from a team you created
    end

    if allowedtodelete == true then
      @membership.destroy

      # now we've got to find if any tasks were assigned to them in the team
      @tasks = Task.find(:all, :conditions => [ "list_id in (select id from lists where team_id = ?) and person_id = ?", @team.id, @person.id ])
      for task in @tasks
        task.person_id = nil
        # yes, i could work out the next person in the rotation, but it's complicated.
        # people aren't often removed from teams so we can just turn off rotation.
        task.rotate = 0
        task.save
      end

      flash[:notice] = @person.name + " has been successfully removed from " + @team.name + "."
    else
      flash[:notice] = "You are not able to remove that person from that team."
      returnto = "workload"
    end

    if returnto == "person"
      # return to person
      redirect_to :controller => 'people', :action => 'show', :id => @person.id
    elsif returnto == "workload"
      redirect_to :controller => 'tasks', :action => 'workload'
    else
      # return to team
      redirect_to :controller => 'teams', :action => 'show', :id => @team.id
    end
  end

end
