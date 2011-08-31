require 'spec_helper'

describe StateMachineWorkflow::RewindCommand do

  class Foo

    attr_accessor :state, :histories

    def initialize(*args, &block)
      @histories = ["bar"]
      super(*args, &block)
    end

    def self.transaction
      yield
    end

    def self.reflect_on_association param
      @@attributes ||= []
      @@attributes.detect{|attribute| attribute == param}
    end

    def self.attributes
      @@attributes
    end

    def self.validated_associated
      return @@validated_associated
    end

    def self.has_one klass_name, params
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

    def previous_state
      "foo"
    end

    def self.validates_associated klass
      @@validated_associated ||= []
      @@validated_associated << klass
    end

    state_machine :state, :initial => :bar do
      command :record_bar do
        transition :bar => :baar
      end

      command :record_baar do
        transition :baar => :qux, :if => lambda{|klass| klass.to_qux }
        transition :baar => :quux
      end

      command :record_qux do
        transition :qux => :corge
      end
    end
  end
  
  class Qux
    attr_accessor :deleted
    def delete
      @deleted = true
    end
  end

  context "when rewinding a class" do
    it "should create a rewind method for each command" do
      foo = Foo.new
      foo.should respond_to(:rewind_record_bar)
    end
    it "should set the state to the previous state" do
      foo = Foo.new
      foo.state = :qux
      foo.histories = ["bar", "baar", "qux"]
      foo.rewind_record_qux
      foo.state.should eql "baar"
    end

    it "should not revert if it is not in the correct state" do
      foo = Foo.new
      foo.state = :qux
      foo.histories = ["bar", "baar", "qux"]
      foo.rewind_record_bar
      foo.state.should eql :qux
    end

    it "should delete the accosiated class if it exists" do
      foo = Foo.new
      foo.state = :qux
      foo.qux = Qux.new
      foo.histories = ["bar", "baar", "qux"]
      foo.rewind_record_qux
      foo.qux.deleted.should be_true
    end
  end

end
