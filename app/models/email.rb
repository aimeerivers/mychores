class Email < ActiveRecord::Base
  
  def self.new_membership_invitation(person, team)
    @email = Email.new
    @email.subject = "New membership invitation from mychores.co.uk"
    @email.message = "Dear #{person.name},

You have been invited to join a team: #{team.name}.

Log into MyChores to accept or decline this invitation. You'll find the links when you log in.

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
    @email.to = person.email
    @email.save
  end
  
  def self.new_membership_request(person, team)
    @email = Email.new
    @email.subject = "New membership request from mychores.co.uk"
    @email.message = "Dear #{team.owner_name},

#{person.name} (#{person.login}) has asked to join your team: #{team.name}.

Log into MyChores to view their profile and accept or decline this request. You'll find the links when you log in.

If you have any problems please email contact@mychores.co.uk

http://www.mychores.co.uk"
    @email.to = team.owner_email
    @email.save
  end
  
end
