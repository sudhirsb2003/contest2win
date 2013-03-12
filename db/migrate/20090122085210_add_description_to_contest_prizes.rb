class AddDescriptionToContestPrizes < ActiveRecord::Migration
  def self.up
    add_column :contest_prizes, :description, :string
  end

  def self.down
    remove_column :contest_prizes, :description
  end
end
