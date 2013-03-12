class AddStatusToContestPrizes < ActiveRecord::Migration
  def self.up
    add_column :contest_prizes, :status, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :contest_prizes, :status
  end
end
