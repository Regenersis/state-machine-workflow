module StateMachineWorkflow
  module Helpers
    def initial_state?
      initial_state.to_s == self.state.to_s
    end

    def initial_state
      self.class.state_machine.initial_state(self).name
    end
  end
end
