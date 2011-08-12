module StateMachineWorkflow
  module Command
    def command(name, *options, &block)
      event(name, &block)
      if name.to_s.start_with?("record")
        update_name = name.to_s.gsub(/^record/, "update").to_sym
        event(update_name, &block)
      end
      owner_class.instance_eval do
        define_method name do |*args|
          self.class.transaction do
            result = self.send('execute_' + name.to_s, *args) && super()
            auto_invoke_command = name.to_s.index('rewind') == 0 ?  "invoke_previous" : "invoke_next"
            raise ::ActiveRecord::Rollback unless result && self.send(auto_invoke_command, *args)
            result
          end
        end

        unless update_name.nil?
          define_method update_name do |*args|
            self.class.transaction do
              result = self.send('execute_' + update_name.to_s, *args) && super()
              auto_invoke_command = update_name.to_s.index('rewind') == 0 ?  "invoke_previous" : "invoke_next"
              raise ::ActiveRecord::Rollback unless result && self.send(auto_invoke_command, *args)
              result
            end
          end
        end

        define_method "invoke_next" do |*args|
          if(self.respond_to?("invoke_" + self.state.to_s))
            return self.send("invoke_" + self.state.to_s, *args)
          end
          true
        end

        define_method "invoke_previous" do |*args|
          if(self.respond_to?("rewind_invoke_" + self.state.to_s))
            return self.send("rewind_invoke_" + self.state.to_s, *args)
          end
          true
        end
      end

      if name.to_s.start_with?("record") || name.to_s.start_with?("invoke")
        rewind_command(name, *options)
      end
    end

    def auto_command(name, *options, &block)
      command(name, *options, &block)
    end
  end
end
