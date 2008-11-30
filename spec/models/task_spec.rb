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
        fake_it_through_to_twitter_update
        @task = Task.new(@task_args)
        
        set_up_mocks_and_variables
        set_up_data_gathering_expectations
        set_up_request_expectations
      end
      
      it "should return message for successful post to twitter" do
        set_up_do_request_expectations(@ok_response)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, and a post made to Twitter."
      end
      
      it "should return message for unsuccessful post to twitter" do
        set_up_do_request_expectations(@ok_response_with_empty_body)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter is currently not working. No post has been made to Twitter."
      end
      
      it "should return message for failed post to twitter" do
        set_up_do_request_expectations(@http_error)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter update failed."
      end
      
      it "should return message for unauthorized post to twitter" do
        set_up_do_request_expectations(@unauthorized_error)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter update failed - please check Twitter password."
      end
      
      it "should return message for twitter unavailable" do
        set_up_do_request_expectations(SocketError)
        message = @task.done(@person, @datecompleted, @personcompleted, @update_twitter)
        message.should == "Task updated, but Twitter is currently unavailable. No post has been made to Twitter."
      end
      
      # helpers
      
      def fake_it_through_to_twitter_update
        # fake it through the first half of the done method
        @task_args = {:one_off => true}
        
        completion = mock("completion")
        Completion.stub!(:new).and_return(completion)
        completion.stub!(:save)
      end
      
      def set_up_mocks_and_variables
        @person = mock("person")
        @person.stub!(:status).and_return("foo")
        @datecompleted = mock("datecompleted")
        @personcompleted = mock("personcompleted")
        @update_twitter = true
        
        @preference = mock("preference")
        @request = mock("request")
        
        @list = mock("list")
        @list.stub!(:valid?).and_return(true)
        @team = mock("team")
        
        @http = mock("http")
        
        @ok_response = Net::HTTPOK.new("200", "1.1", "OK")
        @ok_response.instance_variable_set(:@body, "some text")
        @ok_response.instance_variable_set(:@read, true)
        
        @ok_response_with_empty_body = @ok_response.dup
        @ok_response_with_empty_body.instance_variable_set(:@body, "")
        
        @http_error = Net::HTTPInternalServerError.new("500", "1.1", "Internal Server Error")
        @unauthorized_error = Net::HTTPUnauthorized.new("401", "1.1", "Unauthorized")
        
        @example_email = "mat@example.com"
        @example_password = "foo"
        @obscured_example_password = "sbb"
        @twitter_update_action = "/statuses/update.xml"
        @twitter_url = "twitter.com"
      end
      
      def set_up_data_gathering_expectations
        @task.should_receive(:name).at_least(:once).and_return("one")
        @task.should_receive(:list).at_least(:once).and_return(@list)
        @list.should_receive(:name).at_least(:once).and_return("two")
        @list.should_receive(:team).at_least(:once).and_return(@team)
        @team.should_receive(:name).at_least(:once).and_return("three")
        
        @person.should_receive(:preference).at_least(:once).and_return(@preference)
        @preference.should_receive(:twitter_password).and_return(@obscured_example_password)
        @preference.should_receive(:twitter_email).and_return(@example_email)
        @preference.should_receive(:twitter_update_string).and_return("{TASK} {LIST} {TEAM}")
      end
      
      def set_up_request_expectations
        Net::HTTP::Post.should_receive(:new).with(@twitter_update_action).and_return(@request)
        @request.should_receive(:basic_auth).with(@example_email, @example_password)
        @request.should_receive(:set_form_data).with({"status" => "one two three (www.mychores.co.uk)"})
      end
      
      def set_up_do_request_expectations(response)
        Net::HTTP.should_receive(:new).with(@twitter_url, 80).and_return(@http)
        if response.is_a?(Exception) || (response.is_a?(Class) && response <= Exception)
          @http.should_receive(:start).and_raise(response)
        else
          @http.should_receive(:start).and_yield(@http)
          @http.should_receive(:request).with(@request).and_return(response)
        end
      end
      
    end
  end
  
end
