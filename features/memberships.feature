Feature: Memberships
  In order to share tasks among various people
  As a team member
  I want to invite other people to join my team
  As a non-member
  I want to request to join the team
  
  Background:
    Given a person called 'Alex' with login ID 'al3x'
    And a person called 'Jo' with login ID 'j00'
    And a person called 'Chris' with login ID 'chr1s'
    And a team called 'Household'
    And a list 'Study' for team 'Household'
    And a task 'Dust shelves' for list 'Study'
    And 'Alex' is a member of team 'Household'
    And 'Chris' is a member of team 'Household'
    And 'Alex' is the owner of team 'Household'
  
  Scenario: Alex invites Jo to join a team, who accepts
    Given I am logged in as 'Alex'
    When I visit the page /person/j00
    And I click on 'Invite to join a team'
    Then I should see the text 'Invitation to join a team'
    When I select 'Household' from 'team'
    And I click the 'Invite' button
    Then I should see the text 'An invitation will be sent shortly'
    And I should see the text 'Teams(.*)Household(.*)\(awaiting confirmation\)'
    When I view the team 'Household'
    Then I should see the text 'Team Members(.*)Alex(.*)Jo(.*)\(awaiting confirmation\)'
    And Jo should receive an email
    And that email should have the subject 'New membership invitation from mychores.co.uk'
    And that email should contain 'Dear Jo' in the body
    And that email should contain 'You have been invited to join a team: Household' in the body
    And that email should contain 'Log into MyChores to accept or decline this invitation' in the body
    When I visit my home page
    Then I should see the text 'j00(.*)has not yet joined(.*)Household'
    
    Given I am logged in as 'Jo'
    When I visit my home page
    Then I should see the text 'You have been invited to join(.*)Household'
    And I should NOT see the task 'dust shelves'
    When I click on 'Accept'
    Then I should NOT see the text 'You have been invited to join(.*)Household'
    And I should see the task 'dust shelves'
    And Jo should be a member of the team 'Household'
    
    Given I am logged in as 'Alex'
    When I visit my home page
    Then I should NOT see the text 'j00(.*)has not yet joined(.*)Household'
  
  Scenario: Alex invites Jo to join a team, who declines
    Given I am logged in as 'Alex'
    When I visit the page /person/j00
    And I click on 'Invite to join a team'
    Then I should see the text 'Invitation to join a team'
    When I select 'Household' from 'team'
    And I click the 'Invite' button
    Then Jo should receive an email
    When I visit my home page
    Then I should see the text 'j00(.*)has not yet joined(.*)Household'
    
    Given I am logged in as 'Jo'
    When I visit my home page
    Then I should see the text 'You have been invited to join(.*)Household'
    And I should NOT see the task 'dust shelves'
    When I click on 'Decline'
    Then I should NOT see the text 'You have been invited to join(.*)Household'
    And I should NOT see the task 'dust shelves'
    And Jo should NOT be a member of the team 'Household'
    
    Given I am logged in as 'Alex'
    When I visit my home page
    Then I should NOT see the text 'j00(.*)has not yet joined(.*)Household' 

  
  
  Scenario: Jo requests to join Alex's team and gets accepted
    Given I am logged in as 'Jo'
    When I view the team 'Household'
    And I click on 'Request to join'
    Then I should see the text 'Your request to join this team was noted'
    And I should see the text 'Team Members(.*)Alex(.*)Jo(.*)\(awaiting confirmation\)'
    When I click on 'Jo'
    Then I should see the text 'Teams(.*)Household(.*)\(awaiting confirmation\)'
    And Alex should receive an email
    And that email should have the subject 'New membership request from mychores.co.uk'
    And that email should contain 'Dear Alex' in the body
    And that email should contain 'Jo \(j00\) has asked to join your team: Household' in the body
    And that email should contain 'Log into MyChores to view their profile and accept or decline this request' in the body
    When I visit my home page
    Then I should see the text 'Your request to join(.*)Household(.*)is pending'
    And I should NOT see the task 'dust shelves'
    
    Given I am logged in as 'Alex'
    When I visit my home page
    Then I should see the text 'Jo(.*)wants to join(.*)Household'
    When I click on 'Accept'
    Then I should NOT see the text 'Jo(.*)wants to join(.*)Household'
    And Jo should be a member of the team 'Household'
    
    Given I am logged in as 'Jo'
    When I visit my home page
    Then I should NOT see the text 'Your request to join(.*)Household(.*)is pending'
    And I should see the task 'dust shelves'
  
  Scenario: Jo requests to join Alex's team but gets declined
    Given I am logged in as 'Jo'
    When I view the team 'Household'
    And I click on 'Request to join'
    Then Alex should receive an email
    When I visit my home page
    Then I should see the text 'Your request to join(.*)Household(.*)is pending'
    And I should NOT see the task 'dust shelves'
    
    Given I am logged in as 'Alex'
    When I visit my home page
    Then I should see the text 'Jo(.*)wants to join(.*)Household'
    When I click on 'Decline'
    Then I should NOT see the text 'Jo(.*)wants to join(.*)Household'
    And Jo should NOT be a member of the team 'Household'
    
    Given I am logged in as 'Jo'
    When I visit my home page
    Then I should NOT see the text 'Your request to join(.*)Household(.*)is pending'
    And I should NOT see the task 'dust shelves'
  
  Scenario: Another team member could accept Jo's request
    Given I am logged in as 'Jo'
    When I view the team 'Household'
    And I click on 'Request to join'
    Then Alex should receive an email
    When I visit my home page
    Then I should see the text 'Your request to join(.*)Household(.*)is pending'
    And I should NOT see the task 'dust shelves'
    
    Given I am logged in as 'Chris'
    When I visit my home page
    Then I should see the text 'Jo(.*)wants to join(.*)Household'
    When I click on 'Accept'
    Then I should NOT see the text 'Jo(.*)wants to join(.*)Household'
    And Jo should be a member of the team 'Household'
    
    Given I am logged in as 'Jo'
    When I visit my home page
    Then I should NOT see the text 'Your request to join(.*)Household(.*)is pending'
    And I should see the task 'dust shelves'
    
  Scenario: Another team member could decline Jo's request
    And I am logged in as 'Jo'
    When I view the team 'Household'
    And I click on 'Request to join'
    Then Alex should receive an email
    When I visit my home page
    Then I should see the text 'Your request to join(.*)Household(.*)is pending'
    And I should NOT see the task 'dust shelves'
    
    Given I am logged in as 'Chris'
    When I visit my home page
    Then I should see the text 'Jo(.*)wants to join(.*)Household'
    When I click on 'Decline'
    Then I should NOT see the text 'Jo(.*)wants to join(.*)Household'
    And Jo should NOT be a member of the team 'Household'
    
    Given I am logged in as 'Jo'
    When I visit my home page
    Then I should NOT see the text 'Your request to join(.*)Household(.*)is pending'
    And I should NOT see the task 'dust shelves'
    
  Scenario: Members of a team can remove themselves from it
    Given I am logged in as 'Chris'
    When I view the team 'Household'
    And I click on 'Leave team'
    Then I should see the text 'You have successfully left the team'
    And I should see a link to 'Request to join'
    When I visit my home page
    Then I should NOT see the task 'dust shelves'
    
  Scenario: Members of a team can remove themselves from it
    Given I am logged in as 'Chris'
    When I view the team 'Household'
    And I click on 'Leave team'
    Then I should see the text 'You have successfully left the team'
    And I should see a link to 'Request to join'
    When I visit my home page
    Then I should NOT see the task 'dust shelves'
    
  Scenario: Tasks are reassigned when someone is removed
    Given I am logged in as 'Chris'
    And the task 'dust shelves' is assigned to 'Chris'
    When I view the team 'Household'
    And I click on 'Leave team'
    Then I should see the text 'You have successfully left the team'
    And the task 'dust shelves' should be assigned to the team
    
  Scenario: Owner of the team cannot be removed
    Given I am logged in as 'Alex'
    When I view the team 'Household'
    Then I should NOT see a link to 'Leave team'
    When I try to remove myself from 'Household'
    Then I should see the text 'Sorry, you cannot do that'
    Then Alex should be a member of the team 'Household'
  
