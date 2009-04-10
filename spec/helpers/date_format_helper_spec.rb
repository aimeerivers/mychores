require File.dirname(__FILE__) + '/../spec_helper'

describe DateFormatHelper do
  include DateFormatHelper
  
  describe "time_from_today" do
    before(:each) do
      @today = Date.new(2009,1,1)
    end
    
    it "should return today, tomorrow and yesterday" do
      time_from_today(Date.new(2009,1,1), @today).should == 'today'
      time_from_today(Date.new(2008,12,31), @today).should == 'yesterday'
      time_from_today(Date.new(2009,1,2), @today).should == 'tomorrow'
    end
    
    describe "in the past" do
      it "should return a number of days in the past; up to 10 days" do
        time_from_today(Date.new(2008,12,30), @today).should == '2 days ago'
        time_from_today(Date.new(2008,12,29), @today).should == '3 days ago'
        time_from_today(Date.new(2008,12,28), @today).should == '4 days ago'
        time_from_today(Date.new(2008,12,27), @today).should == '5 days ago'
        time_from_today(Date.new(2008,12,26), @today).should == '6 days ago'
        time_from_today(Date.new(2008,12,25), @today).should == '7 days ago'
        time_from_today(Date.new(2008,12,24), @today).should == '8 days ago'
        time_from_today(Date.new(2008,12,23), @today).should == '9 days ago'
        time_from_today(Date.new(2008,12,22), @today).should == '10 days ago'
      end
    
      it "should return an approximate number of weeks for up to 5 weeks ago" do
        time_from_today(Date.new(2008,12,21), @today).should == '~2 weeks ago'
        time_from_today(Date.new(2008,12,15), @today).should == '~2 weeks ago'
        time_from_today(Date.new(2008,12,14), @today).should == '~3 weeks ago'
        time_from_today(Date.new(2008,12,8), @today).should == '~3 weeks ago'
        time_from_today(Date.new(2008,12,7), @today).should == '~4 weeks ago'
        time_from_today(Date.new(2008,12,1), @today).should == '~4 weeks ago'
        time_from_today(Date.new(2008,11,30), @today).should == '~5 weeks ago'
        time_from_today(Date.new(2008,11,24), @today).should == '~5 weeks ago'
      end
      
      it "should return an approximate number of months for up to 6 months" do
        time_from_today(Date.new(2008,11,23), @today).should == '~2 months ago'
        time_from_today(Date.new(2008,10,25), @today).should == '~2 months ago'
        time_from_today(Date.new(2008,10,24), @today).should == '~3 months ago'
        time_from_today(Date.new(2008,9,25), @today).should == '~3 months ago'
        time_from_today(Date.new(2008,9,24), @today).should == '~4 months ago'
        time_from_today(Date.new(2008,8,26), @today).should == '~4 months ago'
        time_from_today(Date.new(2008,8,25), @today).should == '~5 months ago'
        time_from_today(Date.new(2008,7,27), @today).should == '~5 months ago'
        time_from_today(Date.new(2008,7,26), @today).should == '~6 months ago'
        time_from_today(Date.new(2008,6,27), @today).should == '~6 months ago'
      end
      
      it "should return 'more than 6 months ago' for anything further back - ORLY?!" do
        time_from_today(Date.new(2008,6,26), @today).should == 'more than 6 months ago'
        time_from_today(Date.new(2006,5,11), @today).should == 'more than 6 months ago'
      end
    end
    
    describe "in the future" do
      it "should return a number of days in the future; up to 10 days" do
        time_from_today(Date.new(2009,1,3), @today).should == 'in 2 days'
        time_from_today(Date.new(2009,1,4), @today).should == 'in 3 days'
        time_from_today(Date.new(2009,1,5), @today).should == 'in 4 days'
        time_from_today(Date.new(2009,1,6), @today).should == 'in 5 days'
        time_from_today(Date.new(2009,1,7), @today).should == 'in 6 days'
        time_from_today(Date.new(2009,1,8), @today).should == 'in 7 days'
        time_from_today(Date.new(2009,1,9), @today).should == 'in 8 days'
        time_from_today(Date.new(2009,1,10), @today).should == 'in 9 days'
        time_from_today(Date.new(2009,1,11), @today).should == 'in 10 days'
      end
      
      it "should return an approximate number of weeks for up to 5 weeks" do
        time_from_today(Date.new(2009,1,12), @today).should == 'in ~2 weeks'
        time_from_today(Date.new(2009,1,18), @today).should == 'in ~2 weeks'
        time_from_today(Date.new(2009,1,19), @today).should == 'in ~3 weeks'
        time_from_today(Date.new(2009,1,25), @today).should == 'in ~3 weeks'
        time_from_today(Date.new(2009,1,26), @today).should == 'in ~4 weeks'
        time_from_today(Date.new(2009,2,1), @today).should == 'in ~4 weeks'
        time_from_today(Date.new(2009,2,2), @today).should == 'in ~5 weeks'
        time_from_today(Date.new(2009,2,8), @today).should == 'in ~5 weeks'
      end
      
      it "should return an approximate number of months for up to 6 months" do
        time_from_today(Date.new(2009,2,9), @today).should == 'in ~2 months'
        time_from_today(Date.new(2009,3,10), @today).should == 'in ~2 months'
        time_from_today(Date.new(2009,3,11), @today).should == 'in ~3 months'
        time_from_today(Date.new(2009,4,9), @today).should == 'in ~3 months'
        time_from_today(Date.new(2009,4,10), @today).should == 'in ~4 months'
        time_from_today(Date.new(2009,5,9), @today).should == 'in ~4 months'
        time_from_today(Date.new(2009,5,10), @today).should == 'in ~5 months'
        time_from_today(Date.new(2009,6,8), @today).should == 'in ~5 months'
        time_from_today(Date.new(2009,6,9), @today).should == 'in ~6 months'
        time_from_today(Date.new(2009,7,8), @today).should == 'in ~6 months'
      end
      
      it "should return 'in more than 6 months' for anything further ahead - ORLY?!" do
        time_from_today(Date.new(2009,7,9), @today).should == 'in more than 6 months'
        time_from_today(Date.new(2315,2,14), @today).should == 'in more than 6 months'
      end
    end
  end
end
