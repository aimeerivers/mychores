Feature: Team management
  In order to organise tasks effectively
  As a user of MyChores
  I want to create teams and invite people into them
  
  # Create a new team
  Scenario: User creates a new team
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
  
