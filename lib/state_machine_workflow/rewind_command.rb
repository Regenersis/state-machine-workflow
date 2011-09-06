module StateMachineWorkflow
  module RewindCommand
    def rewind_command(name, *options, &block)
      opts = parse_options(name, *options)
      owner_class.instance_eval do |*args|
        define_method opts[:command_name] do |*args|
          current_state = self.histories.pop
          state_for_transition = opts[:command_name].to_s.gsub("rewind_record_", "")
          if current_state.state != state_for_transition
            return false
          end
          if current_state.respond_to?(:delete)
            current_state.delete
          end
          previous_state = self.histories.last
          self.state = previous_state.state
          result = self.send(opts[:class]).delete if !self.send(opts[:class]).nil?
          if self.respond_to?(:save)
            return self.save
          end
          return true
        end
      end
    end

    def parse_options(name, options = {})
      klass_name = name.to_s.gsub("invoke_", "").gsub("record_", "").gsub("rewind_", "")
      command_name = "rewind_#{name}"
      defaults = {:class => klass_name.to_sym, :command_name => command_name}
      return defaults.merge(options)
    end
  end
end
