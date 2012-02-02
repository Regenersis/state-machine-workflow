module StateMachineWorkflow
  module Process
    def process(process_name, opt = {}, &block)
      options = {:parent_name => :line, :relationship => :has_one}.merge(opt)
      command_name = ('finish_' + process_name.to_s).to_sym
      add_process_helpers_to_class(owner_class)
      setup_relationship(process_name, owner_class, options)
      event(command_name, &block)
      stage_name = set_stage_for_process(process_name, stage_name)
      owner_class.instance_eval do
        define_method command_name do |*args|
          pre_command_method_name = 'execute_' + command_name.to_s
          if self.respond_to? pre_command_method_name
            raise ::ActiveRecord::Rollback unless self.send pre_command_method_name, *args
          end
          self.finish_process
          raise ::ActiveRecord::Rollback unless super()
          self.send("invoke_" + self.state.to_s) if self.respond_to?("invoke_" + self.state.to_s)
          self.start_next_process
          self.publish_event(command_name) if self.respond_to? :publish_event
          true
        end
      end
    end

    private

    def set_stage_for_process(process_name, stage_name)
      stage_name = self.stage_name
      if stage_name != ''
        state process_name do
          define_method :stage do
            stage_name.to_s
          end
        end
      end
      return stage_name
    end

    def setup_relationship(process_name, owner_class, options)
      owner_class.class_eval do
        if options[:relationship] == :has_one
          has_one process_name, :as => options[:parent_name] if self.respond_to?(:has_one)
        elsif options[:relationship] == :has_many
          has_many process_name.to_s.pluralize, :as => options[:parent_name] if self.respond_to?(:has_many)
          owner_class.instance_eval do
            define_method process_name do
              self.send(process_name.to_s.pluralize).last
            end
          end
        end
      end
    end

    def define_latest_version_method(process_name)
      owner_class.class_eval do
        define_method process_name do
          self.send(process_name.to_s.pluralize).last
        end
      end
    end

    def add_process_helpers_to_class(owner_class)
      if !owner_class.included_modules.include?(StateMachineWorkflow::ProcessHelpers)
        owner_class.instance_eval do
          include StateMachineWorkflow::ProcessHelpers
        end
      end
    end
  end
end
