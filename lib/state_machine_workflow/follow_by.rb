module StateMachineWorkflow
  module FollowBy
    def followed_by(process_name, *options)
      state_name = self.name.to_s.gsub(/finish_/, '').to_sym
      if options == []
        transition state_name => process_name
      else
        transition options[0].merge({state_name => process_name})
      end
    end
  end
end
