class History < ActiveRecord::Base
  belongs_to :station, :polymorphic => true
end
