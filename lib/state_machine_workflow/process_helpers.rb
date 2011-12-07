module StateMachineWorkflow
  module ProcessHelpers
    def finish_process
      if self.respond_to?(self.state.to_s)
        property = self.send(state.to_s)
        if property.respond_to?(:finish)
          property.finish(self)
        end
      end
    end

    def start_next_process
      post_command_method_name = 'start_' + self.state
      if self.respond_to?(post_command_method_name)
        raise ::ActiveRecord::Rollback unless self.send(post_command_method_name, self)
      elsif self.respond_to?(self.state.pluralize)
        instance = setup_instance
        collection = self.send("#{self.state.to_s.pluralize}")
        collection << instance
      elsif self.respond_to?(self.state)
        instance = setup_instance
        self.send("#{self.state.to_s}=", instance)
      end
    end

    private

    def setup_instance
      klass = Object.const_get(self.state.to_s.classify)
      instance = klass.new
      if instance.respond_to?(:start)
        instance.start(self)
      end
      instance
    end
  end
end
