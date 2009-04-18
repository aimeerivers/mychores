class Email < ActiveRecord::Base
  
  def self.new_membership_invitation(membership)
    @email = Email.new
    @email.subject = "New membership invitation from mychores.co.uk"
    @email.message = "Dear #{membership.person_name},

You have been invited to join a team: #{membership.team_name}.

Log into MyChores to accept or decline this invitation. You'll find the links when you log in.

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
    @email.to = membership.person_email
    @email.save
  end
  
end
