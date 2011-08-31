module StateMachineWorkflow
  module RewindCommand
    def rewind_command(name, *options, &block)
      opts = parse_options(name, *options)
      owner_class.instance_eval do |*args|
        define_method opts[:command_name] do |*args|
          current_state = self.histories.pop
          state_for_transition = opts[:command_name].to_s.gsub("rewind_record_", "")
          if current_state != state_for_transition
            return false
          end
          previous_state = self.histories.last
          self.state = previous_state
          result = self.send(opts[:class]).delete if !self.send(opts[:class]).nil?
          if self.respond_to?(:save)
            return self.save
          end
          return true
        end
      end
    end

    def parse_options name, *options
      klass_name = name.to_s.gsub("invoke_", "").gsub("record_", "").gsub("rewind_", "")
      command_name = "rewind_#{name}"
      opts = {:class => klass_name.to_sym, :command_name => command_name}
      if !options[0].nil? && options[0][0].class == Hash
        opts = opts.merge(options[0][0])
      end
      return opts
    end
  end
end
