class LinkBidToContestPrizes < ActiveRecord::Migration
  def self.up
    Bid.delete_all
    remove_column :bids, :reverse_auction_id
    add_column :bids, :contest_prize_id, :integer
    add_index :bids, [:contest_prize_id, :value]
    add_index :bids, [:contest_prize_id, :toppled_by_id]
    add_index :bids, [:contest_prize_id, :user_id, :value]
  end

  def self.down
    remove_column :bids, :contest_prize_id
    add_column :bids, :reverse_auction_id, :integer
  end
end
