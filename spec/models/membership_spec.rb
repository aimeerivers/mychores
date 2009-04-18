require File.dirname(__FILE__) + '/../spec_helper'

describe Membership do
  describe "editable_by?" do
    before(:each) do
      @team = mock_model(Team)
      @team.stub!(:member?).and_return(false)
      @person = mock_model(Person)
    end
    
    it "should allow someone to update a membership where they were invited" do
      membership = Membership.new(:team => @team, :person => @person, :invited => true)
      membership.editable_by?(@person).should be_true
    end
    
    it "should not allow someone to update a membership for their own request" do
      membership = Membership.new(:team => @team, :person => @person, :requested => true)
      membership.editable_by?(@person).should be_false
    end
    
    it "should check whether the person is a member of the team in order to update someone else" do
      membership = Membership.new(:team => @team, :person => @person, :requested => true)
      @team.should_receive(:member?).with(@person).and_return(false)
      membership.editable_by?(@person).should be_false
    end
    
    it "should allow a team member to update other memberships" do
      membership = Membership.new(:team => @team, :person => @person, :requested => true)
      @team.should_receive(:member?).with(@person).and_return(true)
      membership.editable_by?(@person).should be_true
    end
  end
  
  describe "deletable_by?" do
    before(:each) do
      @person = mock_model(Person)
      @team = mock_model(Team)
    end
    
    it "should not allow the team owner to be deleted" do
      membership = Membership.new(:person => @person, :team => @team)
      @team.should_receive(:owned_by?).with(@person).and_return(true)
      membership.deletable_by?(@person).should be_false
    end
    
    it "should allow someone to remove themself from the team" do
      membership = Membership.new(:person => @person, :team => @team)
      @team.should_receive(:owned_by?).with(@person).and_return(false)
      membership.deletable_by?(@person).should be_true
    end
    
    it "should allow a team member to remove someone else from the team" do
      person2 = mock_model(Person)
      membership = Membership.new(:person => @person, :team => @team)
      @team.should_receive(:owned_by?).with(@person).and_return(false)
      @team.should_receive(:member?).with(person2).and_return(true)
      membership.deletable_by?(person2).should be_true
    end
    
    it "should not allow a non-member to remove someone else from the team" do
      person2 = mock_model(Person)
      membership = Membership.new(:person => @person, :team => @team)
      @team.should_receive(:owned_by?).with(@person).and_return(false)
      @team.should_receive(:member?).with(person2).and_return(false)
      membership.deletable_by?(person2).should be_false
    end
  end
end
