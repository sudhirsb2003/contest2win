require 'migration_helpers'

class CreateShortListedWinners < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :short_listed_winners do |t|
      t.column "contest_prize_id", :integer, :null => false
      t.column "user_id", :integer, :null => false
      t.column "created_on", :datetime, :null => false
      t.column "confirmed_on", :datetime
    end
    add_index "short_listed_winners", ["contest_prize_id"]
    add_index "short_listed_winners", ["user_id"]
    foreign_key(:short_listed_winners, :user_id, :users)
    foreign_key(:short_listed_winners, :contest_prize_id, :contest_prizes)
  end

  def self.down
    drop_table :short_listed_winners
  end
end
