Feature: New user registration
  As a newbie
  I want to register on MyChores
  So that i can use its wonderful goodness

  Scenario: New user creates registration
    Given we are not logged in
    When we click on 'Register'
    Then we should see the text 'Register'
    When we fill in 'Desired login ID' with 'aimee'
    And we fill in 'Name' with 'Aimee'
    And we fill in 'Choose password' with '12345'
    And we fill in 'Confirm password' with '12345'
    And we fill in 'Email address' with 'aimee@test.com'
    And we click the 'Register' button
    Then we should see the text 'Hi Aimee, thank you for signing up with MyChores'

  Scenario: Test login ID validation
    Given we are not logged in
    When we click on 'Register'
    And we click the 'Register' button
    Then we should see the text 'Login is too short \(minimum is 3 characters\)'
    And we should NOT see the text 'Login can\'t be blank'
    When we fill in 'Desired login ID' with '!!!!!'
    And we click the 'Register' button
    Then we should see the text 'Login can only contain letters and numbers'
    And we should NOT see the text 'Login is too short \(minimum is 3 characters\)'
    When we fill in 'Desired login ID' with 'good_login'
    And we click the 'Register' button
    Then we should NOT see the text 'Login can only contain letters and numbers'
    And we should NOT see the text 'Login is too short \(minimum is 3 characters\)'
    
  Scenario: Test duplicate logins (including with different case sensitivity)
  
  Scenario: Test name validation
  
  Scenario: Test password validation
    Given we are not logged in
    When we click on 'Register'
    And we click the 'Register' button
    Then we should see the text 'Password is too short \(minimum is 5 characters\)'
    And we should NOT see the text 'Password can\'t be blank'
    When we fill in 'Choose password' with 'abcde'
    And we click the 'Register' button
    Then we should see the text 'Password doesn\'t match confirmation'
    And we should NOT see the text 'Password confirmation can\'t be blank'
    When we fill in 'Confirm password' with '12345'
    And we click the 'Register' button
    Then we should see the text 'Password doesn\'t match confirmation'
    When we fill in 'Choose password' with '12345'
    And we click the 'Register' button
    Then we should NOT see the text 'Password doesn\'t match confirmation'
    
  Scenario: Test email validation
  
