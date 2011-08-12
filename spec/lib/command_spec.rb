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
end
