require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Person do

  describe "validation of login id" do

    it "should allow a new person to be saved" do
      person = Person.new(:login => 'test')
      person.errors_on(:login).should == []
    end
    
    it "should allow letters and numbers in the login ID" do
      person = Person.new(:login => '123abc')
      person.errors_on(:login).should == []
    end
    
    it "should actually allow underscores and minus characters too" do
      person = Person.new(:login => '123_ab--c')
      person.errors_on(:login).should == []
    end
    
    it "should certainly not allow spaces in the login ID" do
      person = Person.new(:login => '123 ab -c')
      person.errors_on(:login).should == ['can only contain letters and numbers']
    end
  
  end
  
  describe "confirmed_teams" do
    before(:each) do
      @team1 = mock_model(Team)
      Team.stub!(:find).and_return(@team1)
      @mem1 = mock_model(Membership, :team_id => 1, :confirmed => true)
      @mem2 = mock_model(Membership, :team_id => 2)
      @memberships = [@mem1, @mem2]
      @confirmed_memberships = [@mem1]
      @person = Person.new(:memberships => @memberships)
      @person.stub!(:memberships).and_return(@memberships)
      @memberships.stub!(:confirmed).and_return(@confirmed_memberships)
    end
    
    it "should find the memberships" do
      @person.should_receive(:memberships).and_return(@memberships)
      @memberships.should_receive(:confirmed).and_return(@confirmed_memberships)
      @person.confirmed_teams
    end
    
    it "should look up the teams by memberships" do
      Team.should_receive(:find).with([1]).and_return([@team1])
      @person.confirmed_teams.should == [@team1]
    end
    
    it "should find more than one team" do
      team3 = mock_model(Team)
      mem3 = mock_model(Membership, :team_id => 3, :confirmed => true)
      @memberships.stub!(:confirmed).and_return([@mem1, mem3])
      Team.should_receive(:find).with([1, 3]).and_return([@team1, team3])
      @person.confirmed_teams.should == [@team1, team3]
    end
  end
  
  describe "fellow_team_members" do
    before(:each) do
      @person = Person.new
    end
    
    it "should ask for the confirmed teams" do
      @person.should_receive(:confirmed_teams).and_return([])
      @person.fellow_team_members
    end
    
    it "should look up the confirmed members of all teams, minus yourself" do
      team1 = mock_model(Team)
      team2 = mock_model(Team)
      person2 = mock_model(Person)
      person3 = mock_model(Person)
      @person.stub!(:confirmed_teams).and_return([team1, team2])
      team1.should_receive(:confirmed_members).and_return([@person, person2])
      team2.should_receive(:confirmed_members).and_return([@person, person3])
      @person.fellow_team_members.should == [person2, person3]
    end
    
    it "should not break if a person belongs to no teams" do
      @person.stub!(:confirmed_teams).and_return([])
      @person.fellow_team_members.should == []
    end
    
    it "should not break if a team contains no members" do
      team1 = mock_model(Team)
      @person.stub!(:confirmed_teams).and_return([team1])
      team1.stub!(:confirmed_members).and_return([])
      @person.fellow_team_members.should == []
    end
  end
end
