class AddWinnerFlagToBid < ActiveRecord::Migration
  def self.up
    add_column :bids, :winner, :boolean
    add_index :bids, [:k3b_id, :winner]
  end

  def self.down
    remove_column :bids, :winner
  end
end
