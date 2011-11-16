module StateMachineWorkflow
  module Historiser
    def self.included(klass)
      klass.has_many :histories, :as => :station
    end

    def initialize(*args, &block)
      super(*args, &block)
      self.histories ||= []
      self.histories << History.new(:state => self.initial_state)
    end
  end
end
