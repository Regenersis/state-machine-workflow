require "spec_helper"

describe "workflow helpers" do
  class WorkflowHelperTester

    def state= val
      @state = val
    end

    def state
      @state
    end

    include StateMachineWorkflow::Helpers

    state_machine :state, :initial => :foo do
      event :record_foo do
        transition :foo => :bar
      end

      event :record_bar do
        transition :bar => :baar
      end
    end
  end

  describe "initial_state" do
    it "should return the name of the inital state" do
      workflow_helper_tester = WorkflowHelperTester.new
      workflow_helper_tester.initial_state.should eql :foo
    end
  end

  describe "initial_state?" do
    it "should return true if state machine is in the initial state" do
      workflow_helper_tester = WorkflowHelperTester.new
      workflow_helper_tester.initial_state?.should be_true
    end
  end
end
