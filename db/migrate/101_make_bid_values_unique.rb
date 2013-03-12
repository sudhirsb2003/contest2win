class MakeBidValuesUnique < ActiveRecord::Migration
  def self.up
    remove_index :bids, [:contest_prize_id, :value]
    add_index :bids, [:contest_prize_id, :value], :unique => true 
  end

  def self.down
    remove_index :bids, [:contest_prize_id, :value]
    add_index :bids, [:contest_prize_id, :value], :unique => true 
  end
end
