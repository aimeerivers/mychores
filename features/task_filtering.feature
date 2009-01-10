Feature: Task filtering
  In order to find particular tasks
  As a user viewing the workload list
  I want to filter the tasks that are shown
  
  Scenario: Setup team and tasks
    Given a person called 'Alex' with login ID 'al3x'
    And a person called 'Jo' with login ID 'j00'
    And a team called 'Household'
    And 'Alex' is a member of team 'Household'
    And 'Jo' is a member of team 'Household'
    And a list 'Bedroom' for team 'Household'
    And a task 'Change bed' for list 'Bedroom'
    And the task 'Change bed' is assigned to 'Alex'
    And a task 'Vacuum floor' for list 'Bedroom'
    And the task 'Vacuum floor' is assigned to 'Jo'
    And a task 'Dust shelves' for list 'Bedroom'
    And I am logged in as 'Alex'
    When I view the workload page
    Then I should see the task 'Change bed'
    And I should see the task 'Vacuum floor'
    And I should see the task 'Dust shelves'
    
  Scenario: Filter by person
    GivenScenario: Setup team and tasks
    When I select 'Only my tasks' from 'preference_workload_display'
    And I click the 'Go!' button
    Then I should see the task 'Change bed'
    And I should see the task 'Dust shelves'
    And I should NOT see the task 'Vacuum floor'
    When I select 'Only Jo's tasks' from 'preference_workload_display'
    And I click the 'Go!' button
    Then I should see the task 'Vacuum floor'
    And I should see the task 'Dust shelves'
    And I should NOT see the task 'Change bed'
    
  Scenario: Enable filtering by person in the preferences page too
    GivenScenario: Setup team and tasks
    When I click on 'Preferences'
    And I select 'Only my tasks' from 'preference_workload_display'
    And I click the 'Save preferences' button
    And I view the workload page
    Then I should see the task 'Change bed'
    And I should see the task 'Dust shelves'
    And I should NOT see the task 'Vacuum floor'
    When I click on 'Preferences'
    And I select 'Only Jo's tasks' from 'preference_workload_display'
    And I click the 'Save preferences' button
    And I view the workload page
    Then I should see the task 'Vacuum floor'
    And I should see the task 'Dust shelves'
    And I should NOT see the task 'Change bed'
    
  Scenario: Enable filtering by person in the team view page
    GivenScenario: Setup team and tasks
    When I click on 'Household'
    And I click on 'Team workload'
    And I select 'Only my tasks' from 'preference_workload_display'
    And I click the 'Go!' button
    Then I should see the task 'Change bed'
    And I should see the task 'Dust shelves'
    And I should NOT see the task 'Vacuum floor'
    When I select 'Only Jo's tasks' from 'preference_workload_display'
    And I click the 'Go!' button
    Then I should see the task 'Vacuum floor'
    And I should see the task 'Dust shelves'
    And I should NOT see the task 'Change bed'
