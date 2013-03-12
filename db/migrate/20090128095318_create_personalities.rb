require 'migration_helpers'

class CreatePersonalities < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :personalities do |t|
      t.integer :contest_id, :null => false
      t.string :title, :null => false
      t.string :description
      t.integer :minimum_score, :null => false
      t.integer :maximum_score, :null => false

      t.timestamps
    end
    add_index :personalities, :contest_id
    foreign_key(:personalities, :contest_id, :contests)
  end

  def self.down
    drop_table :personalities
  end
end
