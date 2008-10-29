class InvitationsController < ApplicationController

  def remind
    if params[:id]
      @invitation = Invitation.find(:first, :conditions => [ "code = ? and accepted = 0", params[:id] ])
			
      unless @invitation.nil?
			
        # Send the email
        @email = Email.new
        @email.subject = "Invitation to join a team at mychores.co.uk (reminder)"
        @email.message = @invitation.person.name + " has invited you to join a team at MyChores.co.uk: " + @invitation.team.name + "
	
Please use the following link to sign up and join the team:
http://www.mychores.co.uk/admin/register?code=" + @invitation.code
		      
        @email.to = @invitation.email
        @email.save
				
        flash[:notice] = "An invitation reminder will be sent shortly."
        redirect_to :controller => 'teams', :action => 'show', :id => @invitation.team.id
				
      else
        flash[:notice] = "Sorry, something went wrong. The invitation could not be found."
        redirect_to :controller => 'tasks', :action => 'workload'
      end
			
    else
      flash[:notice] = "Sorry, something went wrong. The invitation could not be found."
      redirect_to :controller => 'tasks', :action => 'workload'
    end
		
  end
	
	
  #	def updateall
  # useful for adding in some controlled fields, eg the code.
  # should not be available all the time.
  #		@invitations = Invitation.find(:all)
  #		for invitation in @invitations
  #			if invitation.code.nil?
  #				invitation.code = Person.sha1(invitation.email + invitation.id.to_s + Time.now.to_s)
  #				invitation.save
  #			end
  #		end
  #	end

end