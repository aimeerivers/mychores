require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Task do

  describe "new task" do
    before(:each) do
      @task = Task.new
    end

    it "should not save without a name" do
      @task.errors_on(:name)[0].should == "can't be blank"
    end

    it "should now allow tasks with name length over 30 characters" do
      @task.name = "1234567890123456789012345678901 blah blah blah as long as you like!"
      @task.errors_on(:name).should == []
    end
    
    it "should not allow to save with a zero or negative recurrence interval" do
      @task.recurrence_interval = 0
      @task.errors_on(:recurrence_interval).should == ['must be greater than 0']
      @task.recurrence_interval = -1
      @task.errors_on(:recurrence_interval).should == ['must be greater than 0']
    end
    
    it "should not allow to save with a non-integer recurrence interval" do
      @task.recurrence_interval = 'abc'
      @task.errors_on(:recurrence_interval).should == ['is not a number']
      @task.recurrence_interval = 3.14159
      @task.errors_on(:recurrence_interval).should == ['is not a number']
    end
    
    it "should allow to save with an integer recurrence interval" do
      @task.recurrence_interval = 159
      @task.errors_on(:recurrence_interval).should == []
    end
  
  end
  
  describe "short_name" do
    
    it "should truncate to 30 characters" do
      task = Task.new(:name => "Vacuum, turn and air bed matress")
      task.short_name.should == "Vacuum, turn and air bed ma..."
    end
    
    it "should allow a task name of exactly 30 characters without truncating it" do
      task = Task.new(:name => "Vacuum, turn & air bed matress")
      task.short_name.should == "Vacuum, turn & air bed matress"
    end

    it "should return shorter names exactly as they are" do
      task = Task.new(:name => 'ping')
      task.short_name.should == task.name
    end
  end
  
  describe "list_name" do
    it "should return empty string if there is no list" do
      task = Task.new
      task.list_name.should == ''
    end
  
    it "should return the name of the list if there is one" do
      task = Task.new(:list => mock_model(List, :name => 'Bedroom'))
      task.list_name.should == 'Bedroom'
    end
  end
  
  describe "describe_recurrence" do
    it "should describe a one off task" do
      task = Task.new(:one_off => true)
      task.describe_recurrence
      task.recurrence_description.should == "One-off task"
    end
    
    it "should describe an every other day task" do
      task = Task.new(:recurrence_measure => "days", :recurrence_interval => 2)
      task.describe_recurrence
      task.recurrence_description.should == "Every other day"
    end
    
    it "should describe a once a week task" do
      task = Task.new(:recurrence_measure => "weeks", :recurrence_interval => 1)
      task.describe_recurrence
      task.recurrence_description.should == "Every week"
    end
    
    it "should describe a once a week on tuesdays task" do
      task = Task.new(:recurrence_measure => "weeks", :recurrence_interval => 1,
                      :recurrence_occur_on => %W{2})
      task.describe_recurrence
      task.recurrence_description.should == "Every week (Tuesday)"
    end
    
    it "should describe a once a week not on tuesdays task" do
      task = Task.new(:recurrence_measure => "weeks", :recurrence_interval => 1,
                      :recurrence_occur_on => %W{0 1 3 4 5 6})
      task.save
      task.describe_recurrence
      task.recurrence_description.should == "Every week (not Tuesday)"
    end
    
    it "should describe a every 3 months task" do
      task = Task.new(:recurrence_measure => "months",
                      :recurrence_interval => 3)
      task.describe_recurrence
      task.recurrence_description.should == "Every 3 months"
    end
  end
  
  describe "done" do
    describe "posting to twitter" do
      
      before(:each) do
        completion = mock("completion")
        Completion.stub!(:new).and_return(completion)
        completion.stub!(:save)
        
        @task = Task.new(:one_off => true)
        @session = mock("twitter session")
        
        @person = mock("person")
        @person.stub!(:status).and_return("foo")
        @datecompleted = mock("datecompleted")
        @personcompleted = mock("personcompleted")
        @update_twitter = true
        
        Twitter::Session.should_receive(:new).with(@person).and_return(@session)
      end
      
      it "should return message for successful post to twitter" do
        @session.should_receive(:update).with(@task).and_return(Twitter::Success.new("body"))
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, and a post made to Twitter."
      end
      
      it "should return message for unsuccessful post to twitter" do
        @session.should_receive(:update).with(@task).and_return(Twitter::ServiceError.new)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter is currently not working. No post has been made to Twitter."
      end
      
      it "should return message for failed post to twitter" do
        @session.should_receive(:update).with(@task).and_return(Twitter::Error.new)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter update failed."
      end
      
      it "should return message for unauthorized post to twitter" do
        @session.should_receive(:update).with(@task).and_return(Twitter::Unauthorized.new)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter update failed - please check Twitter password."
      end
      
      it "should return message for twitter unavailable" do
        @session.should_receive(:update).with(@task).and_return(Twitter::Unavailable.new)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter is currently unavailable. No post has been made to Twitter."
      end
      
    end
  end
  
end
