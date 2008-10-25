require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Setting do

  describe "value" do
    
    before(:each) do
      @setting = Setting.new(:key => 'twitter_username', :value => 'mychores')
      Setting.stub!(:find_by_key).and_return(@setting)
    end

    it "should lookup the setting by value" do
      Setting.should_receive(:find_by_key).with('twitter_username')
      Setting.value('twitter_username')
    end

    it "should return the value of the setting found" do
      Setting.value('twitter_username').should == 'mychores'
    end

    it "should return an empty string if the setting was not found" do
      Setting.stub!(:find_by_key).with('nonsense').and_return(nil)
      Setting.value('nonsense').should == ''
    end

  end
end
