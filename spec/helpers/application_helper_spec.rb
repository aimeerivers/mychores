require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  include ApplicationHelper
  
  describe "javascript_safe" do
    it "should return safe strings with no change" do
      javascript_safe("Party Time!").should == "Party Time!"
    end
    
    it "should remove single quotes" do
      javascript_safe("Jamie's team").should == "Jamies team"
    end
    
    it "should remove double quotes" do
      javascript_safe("Some kind of \"team\"").should == "Some kind of team"
    end
    
    it "should remove both single and double quotes" do
      javascript_safe("Jamie's \"team\"").should == "Jamies team"
    end
  end
  
end
