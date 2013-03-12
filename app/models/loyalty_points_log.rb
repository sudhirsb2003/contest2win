class LoyaltyPointsLog < ActiveRecord::Base
  named_scope :all, :order => :id
end
