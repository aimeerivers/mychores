Feature: New user registration
  As a newbie
  I want to register on MyChores
  So that i can use its wonderful goodness

  Scenario: New user creates registration
    Given we are not logged in
    When we click on 'Register'
    Then we should see the text 'Register'
    When we fill in 'Desired login id' with 'aimee'
    And we fill in 'Name' with 'Aimee'
    And we fill in 'Choose password' with '12345'
    And we fill in 'Confirm password' with '12345'
    And we fill in 'Email address' with 'aimee@test.com'
    # And we somehow, miraculously, get the ReCaptcha right
    And we click the 'Register' button
    # Then we should see the text 'Hi Aimee, thank you for signing up with MyChores!'

  Scenario: Test failed registration attempts