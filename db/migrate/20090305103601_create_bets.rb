require 'migration_helpers'

class CreateBets < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :bets do |t|
      t.integer :wager, :null => false
      t.integer :response_id, :null => false
      t.integer :user_id, :null => false
      t.integer :option_id, :null => false
      t.datetime :created_on, :null => false
    end
    add_index :bets, :option_id
    foreign_key(:bets, :option_id, :question_options)
    add_index :bets, :response_id
    foreign_key(:bets, :response_id, :responses)
  end

  def self.down
    drop_table :bets
  end
end
