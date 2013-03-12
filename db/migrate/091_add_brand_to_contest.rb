require 'migration_helpers'

class AddBrandToContest < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    add_column :contests, :brand_id, :integer
    add_index :contests, :brand_id
    foreign_key(:contests, :brand_id, :brands, false)
  end

  def self.down
    remove_column :contests, :brand_id
  end
end
