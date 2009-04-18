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
  
  Scenario: Another member of the team can edit it
    Given a person called 'Chris' with login ID 'chr1s'
    And 'Chris' is a member of team 'Happy people'
    And I am logged in as 'Chris'
    When I click on 'Happy people'
    And I click on 'Edit team'
    And I fill in 'Team name' with 'Sad people'
    And I click the 'Save team' button
    Then I should see the text 'Sad people'
    
  Scenario: Alex should be able to delete the team
    When I click on 'Delete team'
    Then I should see the text 'Your team was deleted successfully'
    And there should be 0 teams in the database
  
  Scenario: Non-member cannot delete the team
    Given a person called 'Chris' with login ID 'chr1s'
    And I am logged in as 'Chris'
    When I view the team 'Happy people'
    Then I should NOT see a link to 'Delete team'
    When I try to delete the team 'Happy people'
    Then I should see the text 'Sorry, you don\'t have permission to do that'
    And there should be 1 team in the database
  
  Scenario: Someone who is a member of a team but not creator still cannot delete it
    Given a person called 'Chris' with login ID 'chr1s'
    And 'Chris' is a member of team 'Happy people'
    And I am logged in as 'Chris'
    When I click on 'Happy people'
    Then I should NOT see a link to 'Delete team'
    When I try to delete the team 'Happy people'
    Then I should see the text 'Sorry, you don\'t have permission to do that'
    And there should be 1 team in the database
    
  Scenario: Deleting a team should delete the associated lists and tasks
    Given a list 'Kitchen' for team 'Happy people'
    And a list 'Bedroom' for team 'Happy people'
    And a task 'Clean oven' for list 'Kitchen'
    And a task 'Clean fridge' for list 'Kitchen'
    And a task 'Change bed' for list 'Bedroom'
    Given a team called 'Unrelated team'
    And a list 'General' for team 'Unrelated team'
    And a task 'Whatever' for list 'General'
    Then there should be 2 teams in the database
    And there should be 3 lists in the database
    And there should be 4 tasks in the database
    When I click on 'Happy people'
    And I click on 'Delete team'
    Then I should see the text 'Your team was deleted successfully'
    And there should be 1 team in the database
    And there should be 1 list in the database
    And there should be 1 task in the database
    
  Scenario: Logged out person can view the team but not edit or delete it
    Given I am not logged in
    When I view the team 'Happy people'
    Then I should see the text 'hard-working chore-loving people'
    And I should NOT see a link to 'Edit team'
    And I should NOT see a link to 'Delete team'
    When I try to edit the team 'Happy people'
    Then I should see the text 'Please log in'
    When I try to update the team 'Happy people'
    Then I should see the text 'Please log in'
    When I try to delete the team 'Happy people'
    Then I should see the text 'Please log in'
    