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
    
      it "should return an approximate number of weeks for up to 8 weeks ago" do
        time_from_today(Date.new(2008,12,21), @today).should == '~2 weeks ago'
        time_from_today(Date.new(2008,12,15), @today).should == '~2 weeks ago'
        time_from_today(Date.new(2008,12,14), @today).should == '~3 weeks ago'
        time_from_today(Date.new(2008,12,8), @today).should == '~3 weeks ago'
        time_from_today(Date.new(2008,12,7), @today).should == '~4 weeks ago'
        time_from_today(Date.new(2008,12,1), @today).should == '~4 weeks ago'
        time_from_today(Date.new(2008,11,30), @today).should == '~5 weeks ago'
        time_from_today(Date.new(2008,11,24), @today).should == '~5 weeks ago'
        time_from_today(Date.new(2008,11,23), @today).should == '~6 weeks ago'
        time_from_today(Date.new(2008,11,17), @today).should == '~6 weeks ago'
        time_from_today(Date.new(2008,11,16), @today).should == '~7 weeks ago'
        time_from_today(Date.new(2008,11,10), @today).should == '~7 weeks ago'
        time_from_today(Date.new(2008,11,9), @today).should == '~8 weeks ago'
        time_from_today(Date.new(2008,11,3), @today).should == '~8 weeks ago'
      end
      
      it "should return an approximate number of months for a year" do
        time_from_today(Date.new(2008,11,2), @today).should == '~2 months ago'
        time_from_today(Date.new(2008,10,4), @today).should == '~2 months ago'
        time_from_today(Date.new(2008,10,3), @today).should == '~3 months ago'
        time_from_today(Date.new(2008,9,4), @today).should == '~3 months ago'
        time_from_today(Date.new(2008,9,3), @today).should == '~4 months ago'
        time_from_today(Date.new(2008,8,5), @today).should == '~4 months ago'
        time_from_today(Date.new(2008,8,4), @today).should == '~5 months ago'
        time_from_today(Date.new(2008,7,6), @today).should == '~5 months ago'
        time_from_today(Date.new(2008,7,5), @today).should == '~6 months ago'
        time_from_today(Date.new(2008,6,6), @today).should == '~6 months ago'
        time_from_today(Date.new(2008,6,5), @today).should == '~7 months ago'
        time_from_today(Date.new(2008,5,7), @today).should == '~7 months ago'
        time_from_today(Date.new(2008,5,6), @today).should == '~8 months ago'
        time_from_today(Date.new(2008,4,7), @today).should == '~8 months ago'
        time_from_today(Date.new(2008,4,6), @today).should == '~9 months ago'
        time_from_today(Date.new(2008,3,8), @today).should == '~9 months ago'
        time_from_today(Date.new(2008,3,7), @today).should == '~10 months ago'
        time_from_today(Date.new(2008,2,7), @today).should == '~10 months ago'
        time_from_today(Date.new(2008,2,6), @today).should == '~11 months ago'
        time_from_today(Date.new(2008,1,8), @today).should == '~11 months ago'
        time_from_today(Date.new(2008,1,7), @today).should == '~12 months ago'
        time_from_today(Date.new(2008,1,3), @today).should == '~12 months ago'
      end
      
      it "should return a number of years for further back" do
        time_from_today(Date.new(2008,1,2), @today).should == '~1 year ago'
        time_from_today(Date.new(2007,1,3), @today).should == '~1 year ago'
        time_from_today(Date.new(2007,1,2), @today).should == 'over 2 years ago'
        time_from_today(Date.new(2006,1,3), @today).should == 'over 2 years ago'
        time_from_today(Date.new(2006,1,2), @today).should == 'over 3 years ago'
        time_from_today(Date.new(2005,1,3), @today).should == 'over 3 years ago'
        time_from_today(Date.new(1998,9,2), @today).should == 'over 10 years ago'
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
      
      it "should return an approximate number of weeks for up to 8 weeks" do
        time_from_today(Date.new(2009,1,12), @today).should == 'in ~2 weeks'
        time_from_today(Date.new(2009,1,18), @today).should == 'in ~2 weeks'
        time_from_today(Date.new(2009,1,19), @today).should == 'in ~3 weeks'
        time_from_today(Date.new(2009,1,25), @today).should == 'in ~3 weeks'
        time_from_today(Date.new(2009,1,26), @today).should == 'in ~4 weeks'
        time_from_today(Date.new(2009,2,1), @today).should == 'in ~4 weeks'
        time_from_today(Date.new(2009,2,2), @today).should == 'in ~5 weeks'
        time_from_today(Date.new(2009,2,8), @today).should == 'in ~5 weeks'
        time_from_today(Date.new(2009,2,9), @today).should == 'in ~6 weeks'
        time_from_today(Date.new(2009,2,15), @today).should == 'in ~6 weeks'
        time_from_today(Date.new(2009,2,16), @today).should == 'in ~7 weeks'
        time_from_today(Date.new(2009,2,22), @today).should == 'in ~7 weeks'
        time_from_today(Date.new(2009,2,23), @today).should == 'in ~8 weeks'
        time_from_today(Date.new(2009,3,1), @today).should == 'in ~8 weeks'
      end
      
      it "should return an approximate number of months for a year" do
        time_from_today(Date.new(2009,3,2), @today).should == 'in ~2 months'
        time_from_today(Date.new(2009,4,1), @today).should == 'in ~2 months'
        time_from_today(Date.new(2009,4,2), @today).should == 'in ~3 months'
        time_from_today(Date.new(2009,5,1), @today).should == 'in ~3 months'
        time_from_today(Date.new(2009,5,2), @today).should == 'in ~4 months'
        time_from_today(Date.new(2009,5,31), @today).should == 'in ~4 months'
        time_from_today(Date.new(2009,6,1), @today).should == 'in ~5 months'
        time_from_today(Date.new(2009,6,30), @today).should == 'in ~5 months'
        time_from_today(Date.new(2009,7,1), @today).should == 'in ~6 months'
        time_from_today(Date.new(2009,7,30), @today).should == 'in ~6 months'
        time_from_today(Date.new(2009,7,31), @today).should == 'in ~7 months'
        time_from_today(Date.new(2009,8,29), @today).should == 'in ~7 months'
        time_from_today(Date.new(2009,8,30), @today).should == 'in ~8 months'
        time_from_today(Date.new(2009,9,28), @today).should == 'in ~8 months'
        time_from_today(Date.new(2009,9,29), @today).should == 'in ~9 months'
        time_from_today(Date.new(2009,10,27), @today).should == 'in ~9 months'
        time_from_today(Date.new(2009,10,28), @today).should == 'in ~10 months'
        time_from_today(Date.new(2009,11,26), @today).should == 'in ~10 months'
        time_from_today(Date.new(2009,11,27), @today).should == 'in ~11 months'
        time_from_today(Date.new(2009,12,26), @today).should == 'in ~11 months'
        time_from_today(Date.new(2009,12,27), @today).should == 'in ~12 months'
        time_from_today(Date.new(2009,12,31), @today).should == 'in ~12 months'
      end
      
      it "should return a number of years for evermore" do
        time_from_today(Date.new(2010,1,1), @today).should == 'in ~1 year'
        time_from_today(Date.new(2010,12,31), @today).should == 'in ~1 year'
        time_from_today(Date.new(2011,1,1), @today).should == 'in over 2 years'
        time_from_today(Date.new(2011,12,31), @today).should == 'in over 2 years'
        time_from_today(Date.new(2012,1,1), @today).should == 'in over 3 years'
        time_from_today(Date.new(2012,12,30), @today).should == 'in over 3 years'
        time_from_today(Date.new(2012,12,31), @today).should == 'in over 4 years'
        time_from_today(Date.new(2035,2,14), @today).should == 'in over 26 years'
      end
    end
  end
end
