class AddEntryToShortListedWinners < ActiveRecord::Migration
  def self.up
    add_column :short_listed_winners, :entry_id, :integer
    add_column :short_listed_winners, :entry_type, :string
  end

  def self.down
    remove_column :short_listed_winners, :entry_id
    remove_column :short_listed_winners, :entry_type
  end
end
