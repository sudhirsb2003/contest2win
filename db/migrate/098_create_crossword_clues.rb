require 'migration_helpers'

class CreateCrosswordClues < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :crossword_clues do |t|
      t.column :question_id, :integer, :null => false
      t.column :across, :boolean, :null => false
      t.column :row, :integer, :null => false
      t.column :col, :integer, :null => false
      t.column :length, :integer, :null => false
    end
    add_index :crossword_clues, :question_id
    foreign_key(:crossword_clues, :question_id, :questions)
  end

  def self.down
    drop_table :crossword_clues
  end
end
