class AddAcceptedToShortListedWinners < ActiveRecord::Migration
  def self.up
    add_column :short_listed_winners, :accepted, :boolean
    add_index :short_listed_winners, :accepted
  end

  def self.down
    remove_column :short_listed_winners, :accepted
  end
end
