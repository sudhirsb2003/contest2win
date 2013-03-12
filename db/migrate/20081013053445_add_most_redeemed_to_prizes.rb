class AddMostRedeemedToPrizes < ActiveRecord::Migration
  def self.up
    add_column :prizes, :most_redeemed, :boolean
  end

  def self.down
    remove_column :prizes, :most_redeemed
  end
end
