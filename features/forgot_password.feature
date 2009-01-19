Feature: Forgot password
  In order to log in again
  As a user who has forgotten my password
  I want to reset my password
  
  Scenario: Reset password with email address
    Given a person called 'Alex' with login ID 'al3x'
    And I am not logged in
    When I click on 'Forgotten password?'
    Then I should see the text 'Enter your login ID(.*)or email address'
    When I fill in 'login_or_email' with 'alex@test.com'
    And I click the 'Submit' button
    Then I should see the text 'An email will shortly be sent to you with further instructions to change your password'
  
  Scenario: Reset password with login ID
    Given a person called 'Alex' with login ID 'al3x'
    And I am not logged in
    When I click on 'Forgotten password?'
    When I fill in 'login_or_email' with 'al3x'
    And I click the 'Submit' button
    Then I should see the text 'An email will shortly be sent to you with further instructions to change your password'
  
  Scenario: Reset password makes an email get sent
    Given a person called 'Alex' with login ID 'al3x'
    And there are no emails waiting to be sent
    And I am not logged in
    When I click on 'Forgotten password?'
    When I fill in 'login_or_email' with 'al3x'
    And I click the 'Submit' button
    Then there should be 1 email on the queue
    And that email should be addressed to 'Alex@test.com'
    And that email should have the subject 'Password reset link from MyChores'
    And that email should contain 'Dear Alex' in the body
    And that email should contain 'The link below will enable you to change your MyChores password' in the body
    And that email should contain the correct password reset link for Alex
    And that email should contain 'Your login ID is: al3x' in the body
  
  Scenario: Fill in with a non-valid ID and nothing happens
    Given a person called 'Alex' with login ID 'al3x'
    And there are no emails waiting to be sent
    And I am not logged in
    When I click on 'Forgotten password?'
    When I fill in 'login_or_email' with 'whoops!'
    And I click the 'Submit' button
    Then I should see the text 'Login ID or email not found'
    Then there should be 0 emails on the queue
    
  Scenario: Use the link to reset password
    Given a person called 'Alex' with login ID 'al3x'
    And I am not logged in
    When I visit the correct reset password link for Alex
    And I fill in 'person_new_password' with 'chang3d'
    And I fill in 'person_confirm_new_password' with 'chang3d'
    And I click the 'Change' button
    Then I should see the text 'Password changed successfully. You may now login with the new password'
    And I should NOT be logged in
    
  Scenario: Can now log in with the new password
    GivenScenario: Use the link to reset password
    When I click on 'Login'
    And I fill in 'Login ID' with 'al3x'
    And I fill in 'Password' with 'chang3d'
    And I click the 'Login' button
    Then I should be logged in
    
  Scenario: Cannot reset the password unless they match
    Given a person called 'Alex' with login ID 'al3x'
    And I am not logged in
    When I visit the correct reset password link for Alex
    And I fill in 'person_new_password' with 'whoops'
    And I fill in 'person_confirm_new_password' with 'whatan00p'
    And I click the 'Change' button
    Then I should see the text 'New password did not match the confirmation'
    
    
    
    
