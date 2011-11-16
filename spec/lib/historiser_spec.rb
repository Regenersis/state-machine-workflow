require "spec_helper"

describe StateMachineWorkflow::Historiser do
  class HistoriserTestOwner
    def self.has_many klass_name, *args
      @@has_many_associations ||= []
      @@has_many_associations << klass_name
      self.instance_eval do
        define_method klass_name do |*args|
          self.instance_variable_get(:"@#{klass_name}")
        end
        define_method "#{klass_name}=" do |*args|
          self.instance_variable_set(:"@#{klass_name}", *args)
        end
      end
      @@attributes ||= []
      @@attributes << klass_name
    end

    def self.has_many_association_to(klass)
      @@has_many_associations.include?(klass)
    end

    def initial_state
      "balh"
    end

    include StateMachineWorkflow::Historiser
  end

  it "should add a histories association" do
    HistoriserTestOwner.has_many_association_to(:histories).should be_true
  end

end
