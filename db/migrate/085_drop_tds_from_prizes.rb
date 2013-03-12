class DropTdsFromPrizes < ActiveRecord::Migration
  def self.up
    remove_column :prizes, :tds
  end

  def self.down
    remove_column :prizes, :tds, :integer
  end
end
