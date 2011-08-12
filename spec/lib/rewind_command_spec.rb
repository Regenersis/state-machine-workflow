require 'spec_helper'

class RewindCommandExtension
  def self.transaction
    yield
  end

  def publish_event(command, context, *args)
  end

  def reset_history
    self.reset = true
  end

   state_machine :state, :initial => :init do
    command :command do
      transition :init => :completed
    end

    rewind_command :command do
      transition :completed => :init
    end

    rewind_command :pre_command do
      transition :completed => :post_init
    end

    rewind_command :invoke_post_init do
      transition :post_init => :init
    end
  end

  attr_accessor :a1, :a2, :a3, :reset, :parent, :previous_state

  def execute_rewind_command(arg1, arg2, arg3)
    self.a1 = arg1
    self.a2 = arg2
    self.a3 = arg3
  end

  def execute_rewind_pre_command
    self.a1 = "rewind_pre_command_executed"
  end

  def execute_rewind_invoke_post_init
    self.a2 = "rewind_invoke_post_init_executed"
  end

end

describe RewindCommandExtension do
  context "rewind_command" do
    before do
      @machine = RewindCommandExtension.new
      @machine.state = "completed"
      @machine.rewind_command('arg1', 'arg2', 'arg3')
    end

    #should_have_event(:rewind_command)

    it "call execute_command passing all arguments" do
      [@machine.a1, @machine.a2, @machine.a3].should eql ['arg1', 'arg2', 'arg3']
    end

    it "change state to init" do
      @machine.state.should eql 'init'
    end
  end

  context "rewind_command with no block given" do
    class RewindCommandWithoutBlock
      attr_accessor :destination_state, :previous_state

      state_machine :state, :initial => :init do

        command :start do
          transition :init => :state1, :if => lambda {|machine| machine.destination_state == "state1"}
          transition :init => :state2, :if => lambda {|machine| machine.destination_state == "state1"}
        end

        command :complete do
          transition :state1 => :complete
          transition :state2 => :complete
        end

        rewind_command :complete
      end
    end

    before do
      @machine = RewindCommandWithoutBlock.new
    end
    context "rewind_complete" do
      it "transition to init if previous_state is init" do
        @machine.state = "state2"
        @machine.previous_state = "init"
        @machine.rewind_complete_transition.to_name.should eql :init
      end
    end
  end

  context "auto rewind if invoke defined" do
    before do
      @machine = RewindCommandExtension.new
      @machine.state = "completed"
      @machine.previous_state = "post_init"
    end

    it "execute task automatically if it is invoke" do
      @machine.rewind_pre_command

      @machine.a1.should eql "rewind_pre_command_executed"
      @machine.a2.should eql "rewind_invoke_post_init_executed"
    end
  end
end
