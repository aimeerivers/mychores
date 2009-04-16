Feature: Team management
  In order to organise tasks effectively
  As a user of MyChores
  I want to create teams and invite people into them
  
  # Create a new team
  Background:
    Given a person called 'Alex' with login ID 'al3x'
    And I am logged in as 'Alex'
    When I visit my home page
    And I click on 'New team'
    And I fill in 'Team name' with 'Happy people'
    And I fill in 'Description' with 'hard-working chore-loving people'
    And I click the 'Save team' button
    Then I should see the text 'Happy people'
    And I should see the text 'hard-working chore-loving people'
    And Alex should be a member of the team 'Happy people'
  
  Scenario: Alex can edit the team and add or remove colour
    When I click on 'Edit team'
    And I fill in 'Team name' with 'Friendly people'
    And I check 'Use colour'
    And I fill in 'Colour' with '3F2A44'
    And I fill in 'Text colour' with 'D2AFAF'
    And I click the 'Save team' button
    Then I should see the text 'Friendly people'
    And the team should have background colour '3F2A44' and text colour 'D2AFAF'
    When I click on 'Edit team'
    And I uncheck 'Use colour'
    And I click the 'Save team' button
    Then the team should have no background colour
  
  Scenario: Ensure non-member cannot edit the team
    Given a person called 'Chris' with login ID 'chr1s'
    And I am logged in as 'Chris'
    When I view the team 'Happy people'
    Then I should NOT see a link to 'Edit team'
    When I try to edit the team 'Happy people'
    Then I should see the text 'Sorry, you don\'t have permission to do that'
    When I try to update the team 'Happy people'
    Then I should see the text 'Sorry, you don\'t have permission to do that'
    