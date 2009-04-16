require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Twitter::Session do
  before(:each) do
    @person = mock("person")
    @preference = mock("preference")
    
    @person.stub!(:preference).and_return(@preference)
    
    @preference.stub!(:twitter_email).and_return("mat@example.com")
    @preference.stub!(:twitter_password).and_return("sbb")
    @preference.stub!(:twitter_update_string).and_return("{TASK} {LIST} {TEAM}")
    
    @session = Twitter::Session.new(@person)
  end
  
  describe "task_update_string" do
    it "should return a correctly formatted string" do
      @task = mock("task")
      @list = mock("list")
      @team = mock("team")
      
      @task.should_receive(:name).at_least(:once).and_return("one")
      @task.should_receive(:list).at_least(:once).and_return(@list)
      @list.should_receive(:name).at_least(:once).and_return("two")
      @list.should_receive(:team).at_least(:once).and_return(@team)
      @team.should_receive(:name).at_least(:once).and_return("three")
      
      @session.send(:task_update_string, @task).should == "one two three"
    end
  end
  
  describe "do_request" do
    before(:each) do
      @request = mock("request")
      @http = mock("http")
      
      Net::HTTP.should_receive(:new).with("twitter.com", 80).and_return(@http)
    end
    
    it "should return Twitter::Unavailable on SocketError" do
      @http.should_receive(:start).and_raise(SocketError)
      
      result = @session.send(:do_request, @request)
      result.class.should == Twitter::Unavailable
    end
    
    it "should return Twitter::ServiceError on success with empty body" do
      response = Net::HTTPOK.new("200", "1.1", "OK")
      response.instance_variable_set(:@body, "")
      response.instance_variable_set(:@read, true)
      
      @http.should_receive(:start).and_yield(@http)
      @http.should_receive(:request).with(@request).and_return(response)
      
      result = @session.send(:do_request, @request)
      result.class.should == Twitter::ServiceError
    end
    
    it "should return Twitter::Success on success" do
      response = Net::HTTPOK.new("200", "1.1", "OK")
      response.instance_variable_set(:@body, "some text")
      response.instance_variable_set(:@read, true)
      
      @http.should_receive(:start).and_yield(@http)
      @http.should_receive(:request).with(@request).and_return(response)
      
      result = @session.send(:do_request, @request)
      result.class.should == Twitter::Success
    end
    
    it "should return Twitter::Unauthorized on Net::HTTPUnauthorized" do
      response = Net::HTTPUnauthorized.new("401", "1.1", "Unauthorized")
      
      @http.should_receive(:start).and_yield(@http)
      @http.should_receive(:request).with(@request).and_return(response)
      
      result = @session.send(:do_request, @request)
      result.class.should == Twitter::Unauthorized
    end
    
    it "should return Twitter::Error on other HTTP error" do
      response = Net::HTTPInternalServerError.new("500", "1.1", "Internal Server Error")
      
      @http.should_receive(:start).and_yield(@http)
      @http.should_receive(:request).with(@request).and_return(response)
      
      result = @session.send(:do_request, @request)
      result.class.should == Twitter::Error
    end
    
  end
  
  describe "new_request" do
    it "should return a request" do
      request = mock("request")
      form_data = {"status" => "text"}
      action = "/some/action.xml"
      
      Net::HTTP::Post.should_receive(:new).with(action).and_return(request)
      request.should_receive(:basic_auth).with("mat@example.com", "foo")
      request.should_receive(:set_form_data).with(form_data)
      
      result = @session.send(:new_request, action, form_data)
      result.should == request
    end
  end
  
  describe "update" do
    before(:each) do
      @string = mock("string")
      @request = mock("request")
      @response = mock("response")
    end
    
    it "should post to twitter with a task" do
      @task = mock("task")
      
      @session.should_receive(:task_update_string).with(@task).and_return(@string)
      @session.should_receive(:new_request).with("/statuses/update.xml", "status" => @string, 'source' => 'mychores').and_return(@request)
      @session.should_receive(:do_request).with(@request).and_return(@response)
      
      @task.should_receive(:is_a?).with(Task).and_return(true)
      
      result = @session.update(@task)
      result.should == @response
    end
    
    it "should post to twitter with a string" do
      @session.should_receive(:new_request).with("/statuses/update.xml", "status" => @string, 'source' => 'mychores').and_return(@request)
      @session.should_receive(:do_request).with(@request).and_return(@response)
      
      @string.should_receive(:is_a?).with(Task).and_return(false)
      
      result = @session.update(@string)
      result.should == @response
    end
    
  end
  
end