Feature: New user registration
  As a newbie
  I want to register on MyChores
  So that i can use its wonderful goodness

  Scenario: New user creates registration
    Given we are not logged in
    When we click on 'Register'
    Then we should see the text Register