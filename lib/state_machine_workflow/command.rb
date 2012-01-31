module StateMachineWorkflow
  module Command

    def command(name, options={}, &block)
      opts = parse_options(name, options)
      event(name, &block)
      if name.to_s.start_with?("record")
        update_name = create_update_event(name, &block)
      end
      if name.to_s.start_with?("record") || name.to_s.start_with?("invoke")
        add_association_to_class(owner_class, opts )
        include_owner_methods(owner_class, opts[:class])
      end

      owner_class.instance_eval do
        define_method name do |*args|
          self.class.transaction do
            if self.respond_to?('execute_' + name.to_s) #backwords compatability with old version of extensions
              result = self.send('execute_' + name.to_s, *args) && super()
            else
              klass_name = opts[:class]
              build_result = true
              if args[0].class.name == klass_name.to_s.classify
                instance = args.shift
                build_result = instance.build(self, *args) if instance.respond_to?(:build)
              else
                klass = Object.const_get(klass_name.to_s.classify)
                instance = klass.new(args.shift)
                build_result = instance.build(self, *args) if instance.respond_to?(:build)
              end
              result = build_result && self.send("#{opts[:as]}=", instance) && super()
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
                  args.shift
                  if property.respond_to?(:update)
                    result = property.update(self, *args) && super()
                  else
                    result = property.update_attributes(*args) && super()
                  end
                end
              end
              auto_invoke_command = update_name.to_s.index('rewind') == 0 ?  "invoke_previous" : "invoke_next"
              raise ::ActiveRecord::Rollback unless result && self.send(auto_invoke_command, *args)
              if self.respond_to?(:histories)
                self.histories ||= []
                History.create(:state => self.state, :station => self)
              end
              result
            end
          end
        end

        define_method "invoke_next" do |*args|
          if(self.respond_to?("invoke_" + self.state.to_s))
            result = self.send("invoke_" + self.state.to_s)
            return result
          end
          true
        end

        define_method "invoke_previous" do |*args|
          if(self.respond_to?("rewind_invoke_" + self.state.to_s))
            return self.send("rewind_invoke_" + self.state.to_s)
          end
          true
        end
      end

      if name.to_s.start_with?("record") || name.to_s.start_with?("invoke")
        rewind_command(name, options)
      end

      if self.respond_to?("finish_" + self.state) && self.state.nil?
        klass = Object.const_get(self.state.to_s.classify)
        instance = klass.new
        instance.start(self) if instance.respond_to?(:start)
        self.send("#{self.state.to_s}=", instance)
      end
    end

    def auto_command(name, options = {}, &block)
      command(name, options, &block)
    end

    def parse_options(name, options={})
      klass_name = name.to_s.gsub("invoke_", "").gsub("record_", "").gsub("rewind_", "")
      defaults = {:class => klass_name.to_sym, :command_name => name, :parent_name => :station}
      defaults.merge!(options)
      unless defaults.include? :as
        defaults[:as] = defaults[:class]
      end
      return defaults
    end

    private

    def create_update_event(name, &block)
      update_name = name.to_s.gsub(/^record/, "update").to_sym
      event(update_name, &block)
      update_name
    end

    def add_association_to_class(owner_class, opts)
      name = opts[:class]
      parent_name = opts[:parent_name]
      if owner_class.respond_to?(:reflect_on_association) && owner_class.reflect_on_association(name).nil?
        owner_class.class_eval do
          has_one opts[:as], :class_name => name.to_s.classify, :as => parent_name if self.respond_to?(:has_one)
          validates_associated opts[:as] if self.respond_to?(:validates_associated)
        end
      end
    end

    def include_owner_methods(owner_class, class_name)
      module_name = "OwnerMethods"
      klass = Object.const_get(class_name.to_s.classify)
      if klass.const_defined?(module_name)
        owner_class.send(:include, klass.const_get(module_name))
      end
    end
  end
end
