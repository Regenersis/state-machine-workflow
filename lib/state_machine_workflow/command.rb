module StateMachineWorkflow
  module Command

    def command(name, options={}, &block)
      opts = parse_options(name, options)
      event(name, &block)
      if name.to_s.start_with?("record")
        update_name = create_update_event(name, &block)
      end
      if name.to_s.start_with?("record") || name.to_s.start_with?("invoke")
        add_association_to_class(owner_class, opts[:class], opts[:parent_name])
      end

      owner_class.instance_eval do
        define_method name do |*args|
          self.class.transaction do
            if self.respond_to?('execute_' + name.to_s)
              result = self.send('execute_' + name.to_s, *args) && super()
            else
              klass_name = opts[:class]
              if args[0].class == Hash
                klass = Object.const_get(klass_name.to_s.classify)
                instance = klass.new(*args)
                instance.build(*args) if instance.respond_to?(:build)
              else
                instance = args[0]
              end
              result = self.send("#{klass_name}=", instance) && super()
            end
            auto_invoke_command = name.to_s.index('rewind') == 0 ?  "invoke_previous" : "invoke_next"
            raise ::ActiveRecord::Rollback unless result && self.send(auto_invoke_command, *args)
            if self.respond_to?(:histories)
              self.histories ||= []
              History.create(:state => self.state, :station => self)
            end
            result
          end
        end

        unless update_name.nil?
          define_method update_name do |*args|
            self.class.transaction do
              if self.respond_to?('execute_' + update_name.to_s)
                result = self.send('execute_' + update_name.to_s, *args) && super()
              else
                if args[0].class == Hash
                  klass_name = opts[:class]
                  property = self.send("#{klass_name}")
                  if property.respond_to?(:update)
                    result = property.update(*args) && super()
                  else
                    result = property.update_attributes(*args) && super()
                  end
                end
              end
              auto_invoke_command = update_name.to_s.index('rewind') == 0 ?  "invoke_previous" : "invoke_next"
              raise ::ActiveRecord::Rollback unless result && self.send(auto_invoke_command, *args)
              result
            end
          end
        end

        define_method "invoke_next" do |*args|
          if(self.respond_to?("invoke_" + self.state.to_s))
            result = self.send("invoke_" + self.state.to_s, *args)
            return result
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
        rewind_command(name, options)
      end
    end

    def auto_command(name, options = {}, &block)
      command(name, options, &block)
    end

    def parse_options(name, options={})
      klass_name = name.to_s.gsub("invoke_", "").gsub("record_", "").gsub("rewind_", "")
      defaults = {:class => klass_name.to_sym, :command_name => name, :parent_name => :station}
      return defaults.merge(options)
    end

    private

    def create_update_event(name, &block)
      update_name = name.to_s.gsub(/^record/, "update").to_sym
      event(update_name, &block)
      update_name
    end

    def add_association_to_class(owner_class, name, parent_name)
      if owner_class.respond_to?(:reflect_on_association) && owner_class.reflect_on_association(name).nil?
        owner_class.class_eval do
          has_one name, :as => parent_name if self.respond_to?(:has_one)
          validates_associated name if self.respond_to?(:validates_associated)
        end
      end
    end
  end
end
