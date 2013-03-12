require 'migration_helpers'

class CreateRankedEntries < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :ranked_entries do |t|
      t.column :faceoff_id, :integer, :null => false
      t.column :entry_id, :integer, :null => false
      t.column :response_id, :integer, :null => false
      t.column :points, :integer, :null => false
      t.column :sorted, :boolean, :default => false, :null => false
      t.column :upper_bound, :integer
      t.column :lower_bound, :integer
      t.column :created_on, :datetime, :null => false
    end

    add_index :ranked_entries, :faceoff_id
    add_index :ranked_entries, :entry_id
    add_index :ranked_entries, [:response_id, :points]
    foreign_key(:ranked_entries, :response_id, :responses)
    foreign_key(:ranked_entries, :entry_id, :entries)
  end

  def self.down
    drop_table :ranked_entries
  end
end
