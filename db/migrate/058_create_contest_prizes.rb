require 'migration_helpers'

class CreateContestPrizes < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :contest_prizes do |t|
      t.column "prize_id", :integer, :null => false
      t.column "contest_id", :integer, :null => false
      t.column "quantity", :integer, :null => false, :default => 1
      t.column "date", :date, :null => false
      t.column "created_on", :datetime, :null => false
      t.column "created_by_id", :integer, :null => false
    end
    add_index "contest_prizes", ["prize_id"]
    add_index "contest_prizes", ["contest_id"]
    foreign_key(:contest_prizes, :prize_id, :prizes, false)
    foreign_key(:contest_prizes, :contest_id, :contests)
  end

  def self.down
    drop_table :contest_prizes
  end
end
