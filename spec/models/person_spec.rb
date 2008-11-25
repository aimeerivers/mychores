require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Person do

  describe "validation of login id" do

    before(:each) do
      @person = Person.create!(:login => 'test', :name => 'Test',
        :password => 'w00t!', :password_confirmation => 'w00t!',
        :email => 'test@test.com')
    end

    it "should allow a new person to be saved" do
      @person.errors_on(:login).should == []
    end
    
    it "should allow letters and numbers in the login ID" do
      person2 = Person.new(:login => '123abc')
      person2.errors_on(:login).should == []
    end
    
    it "should actually allow underscores and minus characters too" do
      person2 = Person.new(:login => '123_ab--c')
      person2.errors_on(:login).should == []
    end
    
    it "should certainly not allow spaces in the login ID" do
      person2 = Person.new(:login => '123 ab -c')
      person2.errors_on(:login).should == ['can only contain letters and numbers']
    end

    it "should not allow another person to be created with the same login ID" do
      person2 = Person.new(:login => 'test')
      person2.errors_on(:login).should == ['has already been taken']
    end

    it "should not the same login ID, even if the case is different" do
      person2 = Person.new(:login => 'TEST')
      person2.errors_on(:login).should == ['has already been taken']
    end
  
  end
end
