Feature: New user registration
  As a newbie
  I want to register on MyChores
  So that I can use its wonderful goodness

  Scenario: New user creates registration
    Given I am not logged in
    When I click on 'Register'
    Then I should see the text 'Register'
    When I fill in 'Desired login ID' with 'aimee'
    And I fill in 'Name' with 'Aimee'
    And I fill in 'Choose password' with '12345'
    And I fill in 'Confirm password' with '12345'
    And I fill in 'Email address' with 'aimee@test.com'
    And I click the 'Register' button
    Then I should see the text 'Hi Aimee, thank you for signing up with MyChores'

  Scenario: Test login ID validation
    Given I am not logged in
    When I click on 'Register'
    And I click the 'Register' button
    Then I should see the text 'Login is too short \(minimum is 3 characters\)'
    And I should NOT see the text 'Login can\'t be blank'
    When I fill in 'Desired login ID' with '!!!!!'
    And I click the 'Register' button
    Then I should see the text 'Login can only contain letters and numbers'
    And I should NOT see the text 'Login is too short \(minimum is 3 characters\)'
    When I fill in 'Desired login ID' with 'good_login'
    And I click the 'Register' button
    Then I should NOT see the text 'Login can only contain letters and numbers'
    And I should NOT see the text 'Login is too short \(minimum is 3 characters\)'
    
  Scenario: Test duplicate logins (including with different case sensitivity)
    Given a person called 'Aimee' with login ID 'sermoa'
    And I am not logged in
    When I click on 'Register'
    And I fill in 'Desired login ID' with 'sermoa'
    And I click the 'Register' button
    Then I should see the text 'Login has already been taken'
    And I fill in 'Desired login ID' with 'SermOa'
    And I click the 'Register' button
    Then I should see the text 'Login has already been taken'
  
  Scenario: Test name validation
    Given I am not logged in
    When I click on 'Register'
    And I click the 'Register' button
    Then I should see the text 'Name can\'t be blank'
    When I fill in 'Name' with 'Blatantly far too long to ever be acceptable - you just know this is totally going to FAIL!'
    And I click the 'Register' button
    Then I should see the text 'Name is too long \(maximum is 40 characters\)'
    When I fill in 'Name' with '!@£\$%)(*$ <= acceptable!'
    And I click the 'Register' button
    Then I should NOT see the text 'Name can\'t be blank'
    And I should NOT see the text 'Name is too long \(maximum is 40 characters\)'
  
  Scenario: Test password validation
    Given I am not logged in
    When I click on 'Register'
    And I click the 'Register' button
    Then I should see the text 'Password is too short \(minimum is 5 characters\)'
    And I should NOT see the text 'Password can\'t be blank'
    When I fill in 'Choose password' with 'abcde'
    And I click the 'Register' button
    Then I should see the text 'Password doesn\'t match confirmation'
    And I should NOT see the text 'Password confirmation can\'t be blank'
    When I fill in 'Confirm password' with '12345'
    And I click the 'Register' button
    Then I should see the text 'Password doesn\'t match confirmation'
    When I fill in 'Choose password' with '12345'
    And I click the 'Register' button
    Then I should NOT see the text 'Password doesn\'t match confirmation'
    
  Scenario: Test email validation
    Given I am not logged in
    When I click on 'Register'
    And I click the 'Register' button
    Then I should see the text 'Email can\'t be blank'
    And I should NOT see the text 'Email seems to be invalid'
    When I fill in 'Email' with 'not_even_an_email_address'
    And I click the 'Register' button
    Then I should see the text 'Email seems to be invalid'
    And I should NOT see the text 'Email can\'t be blank'
    When I fill in 'Email' with 'wrong@verywrong'
    And I click the 'Register' button
    Then I should see the text 'Email seems to be invalid'
    When I fill in 'Email' with 'good_email@subdomain.good-domain.org.com.jp'
    And I click the 'Register' button
    Then I should NOT see the text 'Email seems to be invalid'
    And I should NOT see the text 'Email can\'t be blank'
    When I fill in 'Email' with 'a@b.co'
    And I click the 'Register' button
    Then I should NOT see the text 'Email seems to be invalid'
    And I should NOT see the text 'Email can\'t be blank'
  
