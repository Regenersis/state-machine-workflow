module StateMachineWorkflow
  module Stage
    attr_accessor :stage_name
    def stage(name)
      self.stage_name = name
      yield
      self.stage_name = ''
    end
  end
end
