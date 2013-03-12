class AddTotalBidsToBids < ActiveRecord::Migration
  def self.up
    add_column :bids, :total_bids, :integer, :null => false, :default => 1
  end

  def self.down
    remove_column :bids, :total_bids
  end
end
