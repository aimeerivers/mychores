require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Task do

  describe "new task" do
    before(:each) do
      @task = Task.new
    end

    it "should not save without a name" do
      @task.errors_on(:name)[0].should == "can't be blank"
    end

    it "should not save if the name is too long" do
      @task.name = "1234567890123456789012345678901"
      @task.errors_on(:name).should == ["is too long (maximum is 30 characters)"]
    end
    
    it "should save if the name is a good length" do
      @task.name = "Clean bathroom mirror"
      @task.errors_on(:name).should == []
    end
  
  end
end
