Feature: New user time zone
  In order to receive my emails at the correct time
  As a new user signing up
  I want the email_time field to be set correctly according to my time zone

  Scenario: New user registers in UK
    Given I am not logged in
    When I click on 'Register'
    Then I should see the text 'Register'
    When I fill in 'Desired login ID' with 'test1'
    And I fill in 'Name' with 'Test'
    And I fill in 'Choose password' with '12345'
    And I fill in 'Confirm password' with '12345'
    And I fill in 'Email address' with 'test@test.com'
    And I click the 'Register' button
    Then I should see the text 'Hi Test, thank you for signing up with MyChores'
    When I click on 'Help centre'
    And I click on 'Email settings'
    Then I should see my email notification time set to 08:00
    And the email time in the database should be set to 08:00

    # Now change to Amsterdam
    When I click on 'Preferences'
    And I select '(GMT+01:00) Amsterdam' from 'person_timezone_name'
    And I click the 'Save preferences' button
    When I click on 'Help centre'
    And I click on 'Email settings'
    Then I should see my email notification time set to 09:00

  Scenario: New user registers in Newfoundland
    Given I am not logged in
    When I click on 'Register'
    Then I should see the text 'Register'
    When I fill in 'Desired login ID' with 'test2'
    And I fill in 'Name' with 'Test'
    And I fill in 'Choose password' with '12345'
    And I fill in 'Confirm password' with '12345'
    And I fill in 'Email address' with 'test@test.com'
    And I select '(GMT-03:30) Newfoundland' from 'person_timezone_name'
    And I click the 'Register' button
    Then I should see the text 'Hi Test, thank you for signing up with MyChores'
    When I click on 'Help centre'
    And I click on 'Email settings'
    Then I should see my email notification time set to 08:00
    And the email time in the database should be set to 11:30

    # Change email time to 10:00
    When I select '10' from 'preference_email_time_4i'
    And I click the 'Save Email settings' button
    Then the email time in the database should be set to 13:30 
    When I click on 'Email settings'
    Then I should see my email notification time set to 10:00

  Scenario: New user registers in New Zealand
    Given I am not logged in
    When I click on 'Register'
    Then I should see the text 'Register'
    When I fill in 'Desired login ID' with 'test3'
    And I fill in 'Name' with 'Test'
    And I fill in 'Choose password' with '12345'
    And I fill in 'Confirm password' with '12345'
    And I fill in 'Email address' with 'test@test.com'
    And I select '(GMT+12:00) Auckland' from 'person_timezone_name'
    And I click the 'Register' button
    Then I should see the text 'Hi Test, thank you for signing up with MyChores'
    When I click on 'Help centre'
    And I click on 'Email settings'
    Then I should see my email notification time set to 08:00
    And the email time in the database should be set to 19:00

    # Change email time to 14:00
    When I select '14' from 'preference_email_time_4i'
    And I click the 'Save Email settings' button
    Then the email time in the database should be set to 01:00 
    When I click on 'Email settings'
    Then I should see my email notification time set to 14:00

    # Now change to Sydney - 2 hours ahead of Auckland
    When I click on 'Preferences'
    And I select '(GMT+10:00) Sydney' from 'person_timezone_name'
    And I click the 'Save preferences' button
    When I click on 'Help centre'
    And I click on 'Email settings'
    Then I should see my email notification time set to 12:00
