class CreateIndexOnShortListedWinnersCreatedOn < ActiveRecord::Migration
  def self.up
    add_index :short_listed_winners, :created_on
  end

  def self.down
    remove_index :short_listed_winners, :created_on
  end
end
