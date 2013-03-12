class ContestRegion < ActiveRecord::Base
  belongs_to :contest
  belongs_to :region

  named_scope :loyalty_points_enabled, :conditions => ["loyalty_points_enabled = ?", true]

end
