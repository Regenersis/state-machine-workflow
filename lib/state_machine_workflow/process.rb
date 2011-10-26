module StateMachineWorkflow
  module Process

    def process(process_name, opt = {}, &block)
      options = {:parent_name => :line}.merge(opt)
      command_name = ('finish_' + process_name.to_s).to_sym

      owner_class.class_eval do
        has_one process_name, :as => options[:parent_name] if self.respond_to?(:has_one)
      end

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
          if self.respond_to?(state.to_s)
            property = self.send(state.to_s)
            if property.respond_to?(:finish)
              property.finish(self)
            end
          end
          raise ::ActiveRecord::Rollback unless super()
          post_command_method_name = 'start_' + self.state
          if self.respond_to?(post_command_method_name)
            raise ::ActiveRecord::Rollback unless self.send(post_command_method_name, self)
          elsif self.respond_to?(self.state)
            klass = Object.const_get(self.state.to_s.classify)
            instance = klass.new
            if instance.respond_to?(:start)
              instance.start(self)
            end
            self.send("#{self.state.to_s}=", instance)
          end
          self.publish_event(command_name, self.send("#{process_name}_job")) if self.respond_to?("#{process_name}_job")
          true
        end
      end
    end
  end
end
