require 'spec_helper'

class ProcessExtension

  def publish_event(command, context, *args)
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

  attr_accessor :workitem, :book_in_job
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

      it "call execute_finish_book_in passing all arguments" do
        @machine.finish_book_in('arg1', 'arg2', 'arg3')
        [@machine.a1, @machine.a2, @machine.a3].should eql ['arg1', 'arg2', 'arg3']
      end

      it "change state to screening" do
        @machine.finish_book_in('arg1', 'arg2', 'arg3')
        @machine.state.should eql 'screening'
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

      it "calls start_screening passing reference" do
        @machine.finish_book_in('arg1', 'arg2', 'arg3')
        @machine.workitem.should eql @machine
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
    class Bar
    end

    class Baar
      attr_accessor :line
      def finish(line)
        @line = line
      end
    end

    class Qux
      attr_accessor :line
      def start(line)
        @line = line
      end
    end

    class Foo
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

      state_machine :state, :initial => :bar do
        process :bar do
          followed_by :baar
        end

        process :baar do
          followed_by :qux
        end
        process :qux do
        end
      end

    end

    it "should add a method for bar" do
      foo = Foo.new
      foo.should respond_to :bar
    end
    context "when transitioning to next state" do
      context "with not start command defined" do
        before do
          @foo = Foo.new
          @foo.finish_bar
        end
        it "should create new object and assign to parent" do
          @foo.baar.should_not be_nil
        end
        it "should creat type based on state" do
          @foo.baar.class.should eql Baar
        end
      end
      context "with a start command defined" do
        before do
          @foo = Foo.new
          @foo.state = "baar"
          @foo.finish_baar
        end
        it "should create new object" do
          @foo.qux.should_not be_nil
        end
        it "should pass the line as paramter" do
          @foo.qux.line.should eql @foo
        end
      end
      context "with a finish command defined" do
        before do
          @foo = Foo.new
          @foo.baar = Baar.new
          @foo.state = "baar"
          @foo.finish_baar
        end
        it "should pass the line as paramter" do
          @foo.baar.line.should eql @foo
        end
      end
    end
  end
end
