require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Person do

  describe "validation of login id" do

    it "should allow a new person to be saved" do
      person = Person.new(:login => 'test')
      person.errors_on(:login).should == []
    end
    
    it "should allow letters and numbers in the login ID" do
      person = Person.new(:login => '123abc')
      person.errors_on(:login).should == []
    end
    
    it "should actually allow underscores and minus characters too" do
      person = Person.new(:login => '123_ab--c')
      person.errors_on(:login).should == []
    end
    
    it "should certainly not allow spaces in the login ID" do
      person = Person.new(:login => '123 ab -c')
      person.errors_on(:login).should == ['can only contain letters and numbers']
    end
  
  end
end
