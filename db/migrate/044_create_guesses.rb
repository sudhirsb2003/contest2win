require 'migration_helpers'

class CreateGuesses < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :guesses do |t|
      t.column 'value',          :string,                          :null => false
      t.column "response_id",      :integer,                         :null => false
      t.column "question_id",      :integer,                         :null => false
      t.column "correct",	      :boolean,                         :null => false, :default => false
      t.column "created_on",      :datetime,                         :null => false
    end
	add_index :guesses, [:response_id, :question_id]
    foreign_key(:guesses, :response_id, :responses)
	add_index :guesses, [:question_id]
    foreign_key(:guesses, :question_id, :questions)
  end

  def self.down
    drop_table :guesses
  end
end
