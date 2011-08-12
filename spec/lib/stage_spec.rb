require 'spec_helper'

class StageExtension
  state_machine :state, :initial => :book_in do

    stage :book_in do
      process :book_in_new do
        followed_by :screening_new
      end
      process :book_in_used do
        followed_by :screening_used
      end
    end

    stage :screening do
      process :screening_new do
        followed_by :dispatch
      end
      process :screening_used do
        followed_by :dispatch
      end
    end
  end

  attr_accessor :a1, :a2, :a3, :reset, :parent

  def execute_command(arg1, arg2, arg3)
    self.a1 = arg1
    self.a2 = arg2
    self.a3 = arg3
  end
end

describe StageExtension do
  context "stage" do
#    should_have_state(:book_in_new)
#    should_have_state(:book_in_used)
#    should_have_state(:screening_new)
#    should_have_state(:screening_used)

    before do
      @machine = StageExtension.new
    end

    it "add stage method to state" do
      @machine.state = 'book_in_new'
      @machine.stage.should eql "book_in"
    end

    it "add stage method to state returning" do
      @machine.state = 'screening_new'
      @machine.stage.should eql "screening"
    end

  end
end
