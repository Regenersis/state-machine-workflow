module StateMachineWorkflow
  module Process
    def process(process_name, *options, &block)
      command_name = ('finish_' + process_name.to_s).to_sym

      event(command_name, &block)

      stage_name = self.stage_name

      if stage_name != ''
        state process_name do
          define_method :stage do
            stage_name.to_s
          end
        end
      end

      owner_class.instance_eval do
        define_method command_name do |*args|
          pre_command_method_name = 'execute_' + command_name.to_s
          if self.respond_to? pre_command_method_name
            raise ::ActiveRecord::Rollback unless self.send pre_command_method_name, *args
          end
          raise ::ActiveRecord::Rollback unless super()
          post_command_method_name = 'start_' + self.state
          raise ::ActiveRecord::Rollback unless self.respond_to?(post_command_method_name) ? self.send(post_command_method_name, self) : true
          self.publish_event(command_name, self.send("#{process_name}_job")) if self.respond_to?("#{process_name}_job")
          true
        end
      end
    end
  end
end
