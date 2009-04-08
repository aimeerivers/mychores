Feature: New user has default tasks
  As a new user just registered
  I want to see a list of default tasks
  So that I have something to get me started
  
  Background:
    Given I am not logged in
    When I click on 'Register'
    And I fill in 'Desired login ID' with 'aimee'
    And I fill in 'Name' with 'Aimee'
    And I fill in 'Choose password' with '12345'
    And I fill in 'Confirm password' with '12345'
    And I fill in 'Email address' with 'aimee@test.com'
    And I click the 'Register' button
    Then I should see the text 'Hi Aimee, thank you for signing up with MyChores'
    
  Scenario: New user sees the workload page
    When I click on 'Click to go to your workload ...'
    Then I should see a workload list showing the default tasks
    
  Scenario: New user sees the hot map view
    When I click on 'Hot map'
    Then I should see the default tasks on the hot map view
    
  Scenario: New user sees the calendar view
    When I click on 'Calendar'
    Then I should see a link to 'General: Water plants'
    And I should see a link to 'Living Room: Plump cushions'
    
  Scenario: New user sees the collage view
  
