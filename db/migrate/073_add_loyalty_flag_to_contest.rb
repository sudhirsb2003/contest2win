class AddLoyaltyFlagToContest < ActiveRecord::Migration
  def self.up
    add_column :contests, :loyalty_points_enabled, :boolean
    add_index :contests, :loyalty_points_enabled
  end

  def self.down
    remove_column :contests, :loyalty_points_enabled
  end
end
