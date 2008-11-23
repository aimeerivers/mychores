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
end
