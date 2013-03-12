require 'migration_helpers'

class CreateResponses < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :responses do |t|
      t.column "user_id",    :integer,  :null => false
      t.column "contest_id", :integer,  :null => false
      t.column "score",      :integer,  :null => false, :default => 0
      t.column "created_on", :datetime, :null => false
    end

    add_index "responses", ["created_on"]
    add_index "responses", ["user_id"]
    foreign_key(:responses, :user_id, :users)
    foreign_key(:responses, :contest_id, :contests)
  end

  def self.down
    drop_table :responses
  end
end
