require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController do
  describe "local?" do
    it "should return true if there is no domain in the referer" do
      controller.local?('/tasks').should be_true
    end
    
    it "should return true if the referer contains the domain" do
      controller.stub!(:request).and_return(mock(:request, :domain => 'mychores.co.uk'))
      controller.local?('http://mychores.co.uk/tasks').should be_true
    end
    
    it "should return false if the referer came from somewhere else" do
      controller.stub!(:request).and_return(mock(:request, :domain => 'mychores.co.uk'))
      controller.local?('http://mail.yahoo.co.uk/randomness/lol').should be_false
    end
  end
  
  describe "home_path" do
    it "should return welcome_path if not logged in" do
      controller.stub!(:logged_in?).and_return(false)
      controller.home_path.should == welcome_path
    end
    
    describe "when logged in" do
      before(:each) do
        controller.stub!(:logged_in?).and_return(true)
        @person = mock_model(Person)
        @session = mock(:session)
        @session.stub!(:[]).with(:person).and_return(@person)
        controller.stub!(:session).and_return(@session)
      end
      
      it "should return the path to the default view - eg workload" do
        @person.stub!(:default_view).and_return('Workload')
        controller.home_path.should == workload_path
      end
      
      it "should return the path to the default view - eg hot map" do
        @person.stub!(:default_view).and_return('Hot map')
        controller.home_path.should == hotmap_path
      end
      
      it "should return the path to the default view - eg calendar" do
        @person.stub!(:default_view).and_return('Calendar')
        controller.home_path.should == calendar_path
      end
      
      it "should return the path to the default view - eg collage" do
        @person.stub!(:default_view).and_return('Collage')
        controller.home_path.should == collage_path
      end
      
      it "should return the path to the default view - eg statistics" do
        @person.stub!(:default_view).and_return('Statistics')
        controller.home_path.should == my_statistics_path
      end
      
      it "should return the workload path if it can't find out otherwise" do
        @person.stub!(:default_view).and_return(nil)
        controller.home_path.should == workload_path
      end
    end
  end
end
