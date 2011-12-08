require 'spec_helper'

class ProcessExtension

  def publish_event(command)
    self.last_event = command
  end

  def self.transaction
    yield
  end

  state_machine :state, :initial => :book_in do
    process :book_in do
      followed_by :screening
    end

    process :screening do
      followed_by :dispatch
    end
  end

  attr_accessor :workitem, :book_in_job, :last_event
  attr_accessor :a1, :a2, :a3, :execute_finish_book_in_return_value, :start_screening_return_value, :execute_finish_screening_return_value

  def execute_finish_book_in(arg1, arg2, arg3)
    self.a1 = arg1
    self.a2 = arg2
    self.a3 = arg3
    self.execute_finish_book_in_return_value
  end

  def start_screening(workitem)
    self.workitem = workitem
    self.start_screening_return_value
  end

end

describe Process do
  context "process" do
    before do
      @machine = ProcessExtension.new
      @machine.execute_finish_book_in_return_value = true
      @machine.start_screening_return_value = true
    end

#    it_have_event(:finish_book_in)
#    it_have_state(:book_in)
#    it_have_state(:screening)

    context "defines method finish_book_in" do

      it "change state to screening" do
        @machine.finish_book_in('arg1', 'arg2', 'arg3')
        @machine.state.should eql 'screening'
      end

      it "publishes event" do
        @machine.finish_book_in('arg1', 'arg2', 'arg3')
        @machine.last_event.should == :finish_book_in
      end

      it "raise ActiveRecord::Rollback and returns false if execute_finish_book_in returns false" do
        @machine.execute_finish_book_in_return_value = false
        lambda {
          result = @machine.finish_book_in('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end

      it "raise ActiveRecord::Rollback and returns false if state transition fails" do
        @machine.state = "screening"
        lambda {
          result = @machine.finish_book_in('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end

      it "return true if start_screening returns true" do
        @machine.finish_book_in('arg1', 'arg2', 'arg3').should be_true
      end

      it "raise ActiveRecord::Rollback and returns false if start_screening returns false" do
        @machine.start_screening_return_value = false
        lambda {
          result = @machine.finish_book_in('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end

      it "not call start_screening if start_screening is not defined and return true" do
        machine = ProcessExtension.new
        machine.execute_finish_book_in_return_value = true
        class << machine
          undef_method(:start_screening)
        end
        result = machine.finish_book_in('arg1', 'arg2', 'arg3')
        machine.workitem.should be_nil
        result.should be_true
      end
    end
  end

  describe "convention based" do
    class Grault
    end

    class Garply
      attr_accessor :line
      def finish(line)
        @line = line
      end
    end

    class Waldo
      attr_accessor :line
      def start(line)
        @line = line
      end
    end

    class Fred
      attr_accessor :line
    end

    class Corge
      def self.has_one klass_name, params={}
        self.instance_eval do
          define_method klass_name do |*args|
            self.instance_variable_get(:"@#{klass_name}")
          end
          define_method "#{klass_name}=" do |*args|
            self.instance_variable_set(:"@#{klass_name}", *args)
          end
        end
      end

      def self.has_many klass_name, params={}
        self.instance_eval do
          define_method klass_name do |*args|
            self.instance_variable_get(:"@#{klass_name}")
          end
          define_method "#{klass_name}=" do |*args|
            self.instance_variable_set(:"@#{klass_name}", *args)
          end
        end
      end

      state_machine :state, :initial => :grault do
        process :grault do
          followed_by :garply
        end

        process :garply do
          followed_by :waldo
        end

        process :waldo do
          followed_by :fred
        end

        process :fred, :relationship => :has_many do
          followed_by :fred
        end
      end

      def publish_event(event_name)
      end

    end

    it "should add a method for bar" do
      foo = Corge.new
      foo.should respond_to :grault
    end
    context "when defining a process" do
      it "should include the process helpers to the instance" do
        Corge.included_modules.should include StateMachineWorkflow::ProcessHelpers
      end
    end
    context "when transitioning to next state" do
      context "with not start command defined" do
        before do
          @foo = Corge.new
          @foo.finish_grault
        end
        it "should create new object and assign to parent" do
          @foo.garply.should_not be_nil
        end
        it "should create type based on state" do
          @foo.garply.class.should eql Garply
        end
      end
      context "with a start command defined" do
        before do
          @foo = Corge.new
          @foo.state = "garply"
          @foo.finish_garply
        end
        it "should create new object" do
          @foo.waldo.should_not be_nil
        end
        it "should pass the line as paramter" do
          @foo.waldo.line.should eql @foo
        end
      end
      context "with a finish command defined" do
        before do
          @foo = Corge.new
          @foo.garply = Garply.new
          @foo.state = "garply"
          @foo.finish_garply
        end
        it "should pass the line as paramter" do
          @foo.garply.line.should eql @foo
        end
      end
    end

    context "when relationship is defined for transition" do
      before do
        @foo = Corge.new
        @foo.state = "fred"
      end

      it "should define add a has many reletionship" do
        @foo.should respond_to :freds
      end

      it "should create a method to return the last object in the array" do
        fred_west = "wrong"
        fred_bundy = "wrong"
        fred_flintstone = "right"
        @foo.freds = [fred_west, fred_bundy, fred_flintstone]
        @foo.fred.should eql fred_flintstone
      end

      it "should add a new instance to the collection when starting the transition" do
        @foo.state = "waldo"
        @foo.freds = []
        @foo.finish_waldo
        @foo.freds.length.should eql 1
      end

      it "should add if transitions back to itself" do
        @foo.state = "fred"
        @foo.freds = []
        @foo.finish_fred
        @foo.finish_fred
        @foo.freds.length.should eql 2
      end

    end
  end
end
