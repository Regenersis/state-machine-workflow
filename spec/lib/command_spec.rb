require 'spec_helper'

class CommandExtension

  def self.transaction
    yield
  end
  
  state_machine :state, :initial => :init do
    command :command do
      transition :init => :completed
    end

    command :record_action do
      transition :init => :completed
    end

    command :pre_command do
      transition :init => :pre_complete
    end

    auto_command :invoke_pre_complete do
      transition :pre_complete => :completed
    end
  end

  attr_accessor :a1, :a2, :a3, :execute_command_return_value

  def execute_command(arg1, arg2, arg3)
    self.a1 = arg1
    self.a2 = arg2
    self.a3 = arg3
    execute_command_return_value
  end

  def execute_update_action(arg1, arg2, arg3)
    self.a1 = arg1
    self.a2 = arg2
    self.a3 = arg3
    execute_command_return_value
  end

  def execute_pre_command
    self.a1 = "pre_command_executed"
  end

  def execute_invoke_pre_complete
    self.a2 = "next_command_executed"
    execute_command_return_value
  end
end

describe StateMachineWorkflow::Command do
  context "command" do
    before do
      @machine = CommandExtension.new
      @machine.execute_command_return_value = true
    end

 #   should_have_event(:command)
 #   should_have_event(:record_action)
 #   should_have_event(:update_action)

    context "defines method command which" do

      it "calls execute_command method passing all arguments" do
        @machine.command('arg1', 'arg2', 'arg3')
        [@machine.a1, @machine.a2, @machine.a3].should eql ['arg1', 'arg2', 'arg3']
      end
      it "change state according to transition" do
        @machine.command('arg1', 'arg2', 'arg3')
        @machine.state.should eql 'completed',
      end

      it "return true" do
        @machine.command('arg1', 'arg2', 'arg3').should be_true
      end

      it "raise ActiveRecord::Rollback and returns false if execute_command returns false" do
        @machine.execute_command_return_value = false
        lambda {
          result = @machine.command('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end

      it "raise ActiveRecord::Rollback and returns false if state transition fails" do
        @machine.state = "completed"
        lambda {
          result = @machine.command('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end

      it "execute task automatically if it is invoke" do
        @machine.pre_command

        @machine.a1.should eql "pre_command_executed"
        @machine.a2.should eql "next_command_executed"
      end

      it "raise ActiveRecord::Rollback and return false if second transition fails" do
        @machine.execute_command_return_value = false
        lambda {
          result = @machine.pre_command
        }.should raise_error(ActiveRecord::Rollback)
      end
    end

    context "when defining command" do
      it "A rewind command for command" do
        @machine.should respond_to(:rewind_record_action)
      end
    end

    context "defines update method for record_action when starts with record which" do
      it "calls execute_update_action method passing all arguments" do
        @machine.update_action('arg1', 'arg2', 'arg3')
        [@machine.a1, @machine.a2, @machine.a3].should eql ['arg1', 'arg2', 'arg3']
      end

      it "change state according to transition" do
        @machine.update_action('arg1', 'arg2', 'arg3')
        @machine.state.should eql 'completed'
      end

      it "return true" do
        @machine.update_action('arg1', 'arg2', 'arg3').should be_true
      end

      it "raise ActiveRecord::Rollback and returns false if execute_command returns false" do
        @machine.execute_command_return_value = false
        lambda {
            result = @machine.update_action('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end

      it "raise ActiveRecord::Rollback and returns false if state transition fails" do
        @machine.state = "completed"
        lambda {
            result = @machine.update_action('arg1', 'arg2', 'arg3')
        }.should raise_error(ActiveRecord::Rollback)
      end
    end
  end

  describe "create associations" do
    class Foo
      attr_accessor :bar, :qux
      def initialize(params)
        self.bar = params[:bar]
        self.qux = params[:qux]
      end

      def update_attributes params
        self.bar = params[:bar]
        self.qux = params[:qux]
        true
      end
    end

    class Bar
      attr_accessor :result, :update_result, :deleted
      def build params
        @result = params
      end

      def update params
        @update_result = params
      end
      def delete
        @deleted = true
      end
    end

    class Qux
    end

    class Quux
    end

    class AssociationTest
      attr_accessor :histories


      def self.transaction
        yield
      end

      def self.reflect_on_association param
        @@attributes ||= []
        @@attributes.detect{|attribute| attribute == param}
      end

      def self.attributes
        @@attributes
      end

      def self.validated_associated
        return @@validated_associated
      end

      def self.has_one klass_name, params
        self.instance_eval do
          define_method klass_name do |*args|
            self.instance_variable_get(:"@#{klass_name}")
          end
          define_method "#{klass_name}=" do |*args|
            self.instance_variable_set(:"@#{klass_name}", *args)
          end
        end
        @@attributes ||= []
        @@attributes << klass_name
      end

      def previous_state
        "foo"
      end

      def self.validates_associated klass
        @@validated_associated ||= []
        @@validated_associated << klass
      end

      state_machine :state, :initial => :foo do
        command :record_foo do
          transition :foo => :bar
        end
        command :record_bar do
          transition :bar => :qux
        end

        command :record_qux do
          transition :qux => :quux
        end
        command :invoke_quux do
          transition :quux => :corge
        end
        command :record_alias_command, :class => :qux do
          transition :alias_command => :zxzzy
        end
      end
    end

    before do
      @history = []
      History.stub(:create){|*args| @history << args[0][:state]  }
      @association_test = AssociationTest.new
    end

    it "should add an method called foo" do
      @association_test.should respond_to :foo
    end

    it "should add all attributes" do
      AssociationTest.attributes.should eql [:foo, :bar, :qux, :quux]
    end

    it "should set the validates associated klass" do
      AssociationTest.validated_associated.should eql [:foo, :bar, :qux, :quux]
    end

    context "when transitioning state with new object" do
      before do
        @params = {:bar => "quux", :qux => "corge"}
      end
      it "should set the association value when transitioning" do
        klass_instance = Foo.new(@params)
        @association_test.record_foo(klass_instance)
        @association_test.foo.should eql klass_instance
        @association_test.state.should eql "bar"
      end

      it "should create a new object to param is hash" do
        @association_test.record_foo(@params)
        @association_test.foo.bar.should eql @params[:bar]
        @association_test.foo.qux.should eql @params[:qux]
      end

      it "activate the build method if one exists on the instance" do
        @association_test.state = "bar"
        @association_test.record_bar(@params)
        @association_test.bar.result.should eql @params
      end

      it "should record its history" do
        klass_instance = Foo.new(@params)
        @association_test.record_foo(klass_instance)
        @history.should eql ["bar"]
      end
    end

    context "when transitioning state when updating an object" do
      before do
        @params = {:bar => "quux", :qux => "corge"}
        @update_params = {:bar => "grault", :qux => "graply"}
      end

      it "should set the association value when transitioning" do
        @association_test.foo = Foo.new(@params)
        @association_test.update_foo(@update_params)
        @association_test.state.should eql "bar"
      end

      it "should create a new object to param is hash" do
        @association_test.foo = Foo.new(@params)
        @association_test.update_foo(@update_params)
        @association_test.foo.bar.should eql @update_params[:bar]
        @association_test.foo.qux.should eql @update_params[:qux]
      end

      it "activate the update method if one exists on the instance" do
        @association_test.bar = Bar.new(@params)
        @association_test.state = "bar"
        @association_test.update_bar(@update_params)
        @association_test.bar.update_result.should eql @update_params
      end
    end

    context "when using an auto command the command" do
      it "activate the update method if one exists on the instance" do
        @params = {:bar => "quux", :qux => "corge"}
        @association_test.state = "qux"
        @association_test.record_qux(@params)
        @association_test.state.should eql "corge"
      end
    end

    context "when executing an alias command" do
      it "should set the alias class" do
        @params = {:bar => "quux", :qux => "corge"}
        klass_instance = Qux.new(@params)
        @association_test.state = "alias_command"
        @association_test.record_alias_command(klass_instance)
        @association_test.qux.should eql klass_instance
        @association_test.state.should eql "zxzzy"
      end
    end
  end

  context "parse options" do
    context "when options are empty" do
      class TestClass
        include StateMachineWorkflow::Command
      end

      it "should pass back a hash with the correct class name with record command" do
        TestClass.new.parse_options("record_command").should eql({:class => :command, :command_name => "record_command"})
      end
      it "should pass back a hash with the correct class name with record invoke" do
        TestClass.new.parse_options("invoke_command").should eql({:class => :command, :command_name => "invoke_command"})
      end
      it "should pass back a hash with the correct class name with record rewind command" do
        TestClass.new.parse_options("rewind_record_command").should eql({:class => :command, :command_name => "rewind_record_command"})
      end
      it "should pass back a hash with the correct class name with invoke rewind command" do
        TestClass.new.parse_options("rewind_invoke_command").should eql({:class => :command, :command_name => "rewind_invoke_command"})
      end
    end
    context "when the option contains a class" do
      it "should pass back a hash with the correct class name provided" do
        TestClass.new.parse_options("record_my_same_command", [{:class => :command}]).should eql({:class => :command, :command_name => "record_my_same_command"})
      end
    end
  end
end
