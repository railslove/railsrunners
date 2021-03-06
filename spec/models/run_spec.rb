require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Run do

  it { should have_many(:participants) }
  it { should have_many(:distances) }
  it { should belong_to(:user) }

  describe '#encode_google_map' do

    before(:each) do
      # maybe use rspec subjects
      @future_run = Factory.build(:future_run, :msid => "211270727460700862622.0004ae3543b46f1649927")
    end

    it 'set the proper map url' do
      response = "http://maps.google.com/maps/api/staticmap?sensor=false&size=950x300&path=enc%3A_osuDh%7EwdPko%40zb%40sFpDdUxe%40%60FrPzElTxAda%40rAfk%40iN%7E_%40eJnWcQhYcQvXtVnQ"
      FakeWeb.register_uri(:get, "http://static-maps-generator.appspot.com/url?msid=#{@future_run.msid}&size=950x300", :body => response)
      @future_run.send(:encode_google_map)      
      @future_run.map_url.should eql "http://maps.google.com/maps/api/staticmap?sensor=false&size=950x300&path=enc%3A_osuDh%7EwdPko%40zb%40sFpDdUxe%40%60FrPzElTxAda%40rAfk%40iN%7E_%40eJnWcQhYcQvXtVnQ"
    end

  end

  context "#save" do
    
    context "when msid changed?" do

      it "should encode the url" do
        @future_run = Factory.build(:future_run, :msid => "211270727460700862622.0004ae3543b46f1649927")
        @future_run.should be_msid_changed
        @future_run.should_receive(:encode_google_map)
        @future_run.save!        
      end

    end

    context "when msid not changed?" do

      it "shouldn't encode the url" do
        @future_run = Factory.build(:future_run)
        @future_run.should_not_receive(:encode_google_map)
        @future_run.save!        
      end

    end

  end

  describe 'scopes' do

      before(:each) do
        @past_run = Factory.build(:past_run)
        @future_run = Factory.build(:future_run)
        @past_run.save(:validate => false)
        @future_run.save
      end

    it 'should get runs in the past' do
      Run.past.should include @past_run
      Run.past.should_not include @future_run          
    end

    it 'should get runs in the future' do
      Run.registerable.should include @future_run
      Run.registerable.should_not include @past_run    
    end
  end
  
  describe 'validations' do
    it 'does not allow to create an event in past' do
      run = Run.new(:start_at => 3.days.ago)
      run.valid?
      run.errors.full_messages.should include("You can't add a run in past")
    end

    it 'does not allow missing name, user and distances or start_at' do
      run = Run.new
      run.valid?
      [:user, :name, :distances, :start_at].each do |field|
        run.errors[field].should include "can't be blank"
      end
    end

    it 'does not allow any other values than url for url fields' do
      run = Run.new(:url => "blabla.com", :charity_url => "blubli.com")      
      run.valid?
      [:url, :charity_url].each do |field|
        run.errors[field].should include "is invalid"
      end
    end 

     it 'shouldnt be validated if no address is given' do
      run = Run.new(:url => "http://blabla.com", :charity_url => "http://blubli.com") 
      run.valid?
      run.errors[:map_url].should_not include "This isn't a google maps url"
     end

      it 'shouldnt be validated if no address is given' do
        run = Run.new(:url => "http://blabla.com", :charity_url => "http://blubli.com", :map_url => "http://maps.google.com/a_fucking_cool_map") 
        run.valid?
        run.errors[:map_url].should_not include "This isn't a google maps url"
     end
  end

  describe 'visual_name' do
    before(:each) do
      @run = Factory.build(:run, :name => "My super duper run")
    end

    describe 'only one distance' do
      it "displays integer values without comma" do
        @run.distances = []
        @run.distances << Factory(:distance, :distance_in_km => 9)
        @run.save!

        @run.visual_name.should eq "My super duper run (9 km)"
        @run.visual_name('mi').should eq "My super duper run (5.59 mi)"
      end

      it "displays float values exactly" do
        @run.distances = []
        @run.distances << Factory(:distance, :distance_in_km => 5.5)
        @run.save!

        @run.visual_name.should eq "My super duper run (5.5 km)"
        @run.visual_name('mi').should eq "My super duper run (3.42 mi)"
      end
    end

    describe 'many distances' do
      before(:each) do
        @distances = []
      end

      it "displays integer values without comma" do
        5.times do |i|
          @distances << Factory(:distance, :distance_in_km => i+1)
        end
        @run.distances << @distances

        @run.visual_name.should eq("My super duper run (1 km - 5 km)")
        @run.visual_name('mi').should eq("My super duper run (0.62 mi - 3.11 mi)")
      end

      it "displays float values exactly" do
        5.times do |i|
          @distances << Factory(:distance, :distance_in_km => i+1.5)
        end
        @run.distances << @distances

        @run.visual_name.should eq("My super duper run (1.5 km - 5.5 km)")
        @run.visual_name('mi').should eq("My super duper run (0.93 mi - 3.42 mi)")
      end
    end
  end
end