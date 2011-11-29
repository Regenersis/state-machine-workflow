class Hazar
  attr_accessor :deleted
  def delete
    @deleted = true
  end
end

class Qux
  attr_accessor :deleted
  def delete
    @deleted = true
  end
end

class HistoryStub
  attr_accessor :state
  def initialize state_hash
    @state = state_hash[:state]
  end

  def delete
  end
end

class Bar
  attr_accessor :result, :update_result, :deleted
  def build owner, *params
    @result = params
  end

  def update params
    @update_result = params
  end
  def delete
    @deleted = true
  end
end

class Qux
end

class JizzMister
end

class Quux
  attr_accessor :owner

  def build(owner, *args)
    @owner = owner
    false
  end
end

class Foo
  attr_accessor :bar, :qux
  def initialize(params)
    self.bar = params[:bar]
    self.qux = params[:qux]
  end

  def update_attributes params
    self.bar = params[:bar]
    self.qux = params[:qux]
    true
  end

  module OwnerMethods
    def hello_world
      "hello world"
    end
  end
end
