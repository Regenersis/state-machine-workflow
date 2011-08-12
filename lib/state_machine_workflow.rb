require "active_record"
require "state_machine"
Dir.glob(File.join(File.dirname(__FILE__), "state_machine_workflow/**/*.rb")).each{|file| require file}

module StateMachineWorkflow
end

module StateMachine
  class Machine
    include StateMachineWorkflow::Command
    include StateMachineWorkflow::RewindCommand
    include StateMachineWorkflow::Process
    include StateMachineWorkflow::Stage
  end

  class Event
    include StateMachineWorkflow::FollowBy
  end
end
