Feature: Testimonials
  In order to promote the site
  As a site owner
  I want people to add testimonials which i approve and can be seen in the navigator
  
  Background: #User makes a testimonial
    Given a person called 'Alex' with login ID 'al3x'
    And I am logged in as 'Alex'
    And there are no emails waiting to be sent
    When I visit the page /testimonials
    Then I should see the text 'There are currently no approved testimonials.'
    When I click on 'Submit a testimonial'
    Then the text field with id 'testimonial_name' should be filled in with 'Alex'
    And the text field with id 'testimonial_login_id' should be filled in with 'al3x'
    And I should NOT see the text 'Short version'
    And I should NOT see the text 'Approved'
    When I fill in 'Testimonial' with 'omg i love mychores!!'
    And I click the 'Submit testimonial' button
    Then I should see the text 'Thank you. Your testimonial will appear here once approved.'
    
  Scenario: Alex cannot yet see the testimonial
    When I visit the welcome page
    Then I should NOT see the text 'Testimonials'
    When I visit the page /testimonials
    Then I should see the text 'There are currently no approved testimonials.'
    
  Scenario: Alex cannot edit the testimonial
    When I visit the edit page for the latest testimonial
    Then I should be denied access
    And I should NOT see the text 'Edit Testimonial'
  
  Scenario: Admin should receive an email
    Then there should be 1 email on the queue
    And that email should be addressed to 'contact@mychores.co.uk'
    And that email should have the subject 'New MyChores testimonial from Alex (al3x)'
    And that email should contain 'omg i love mychores!!' in the body
    And that email should contain a link to edit the latest testimonial
    
  Scenario: Admin edit the testimonial and then it is visible
    Given an administrator called 'Aimee' with login ID 'sermoa'
    And I am logged in as 'Aimee'
    When I visit the edit page for the latest testimonial
    Then I should see the text 'Edit testimonial'
    And I should see the text 'Short version'
    And I should see the text 'Approved'
    And I should NOT see the text 'reCAPTCHA'
    When I check 'Approved'
    And I click the 'Save' button
    Then I should see the text 'Testimonial was successfully updated.'
    And I should see the text 'omg i love mychores!!'
    When I log out
    Then I should see the text 'Testimonials'
    Then I should see the text 'omg i love mychores!!'
    
    