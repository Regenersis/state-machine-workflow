module StateMachineWorkflow
  module RewindCommand
    def rewind_command(name, *options, &block)
      rewind_command_name = ('rewind_' + name.to_s).to_sym
      if block == nil
        command(rewind_command_name, *options) do
          original_command = self.machine.events.find {|e| e.name == name}
          original_command.branches.each do |guard|
            guard.state_requirements.each do |req|
              req[:from].values.each do |from_state|
                self.machine.states.each do |to_state|
                  transition from_state => to_state.name, :if => lambda {|machine| machine.previous_state == to_state.name.to_s}
                end
              end
            end
          end
        end
      else
        command(rewind_command_name, *options, &block)
      end
    end
  end
end
