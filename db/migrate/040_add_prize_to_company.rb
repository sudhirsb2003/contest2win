require 'migration_helpers'

class AddPrizeToCompany < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    add_column :contests, :prize_id, :integer
    add_index :contests, :prize_id
    foreign_key(:contests, :prize_id, :prizes, false)
  end

  def self.down
    remove_column :contests, :prize_id
  end
end
