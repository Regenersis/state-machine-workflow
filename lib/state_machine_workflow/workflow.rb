module StateMachineWorkflow
  module Workflow
    def record_transition(owner_class, opts, *args)
      klass_name = opts[:class]
      build_result = true
      if args[0].class == Hash || args.empty?
        klass = Object.const_get(klass_name.to_s.classify)
        instance = klass.new(*args)
        build_result = instance.build(owner_class, *args) if instance.respond_to?(:build)
      else
        instance = args[0]
        build_result = instance.build(owner_class, *args) if instance.respond_to?(:build)
      end
      result = owner_class.send("#{klass_name}=", instance) && build_result
    end

    def update_transaction(owner_class, opts, *args)
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
  end

end
