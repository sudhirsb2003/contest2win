require 'migration_helpers'

class CreateVotes < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :votes do |t|
      t.column "voteable_id", :integer,                 :null => false
      t.column "points",      :integer,  :default => 1, :null => false
      t.column "user_id",     :integer,                 :null => false
      t.column "created_on",  :datetime,                :null => false
    end

    add_index "votes", ["user_id"]
    add_index "votes", ["voteable_id", "user_id"], :unique => true
    add_index "votes", ["voteable_id"]
    foreign_key(:votes, :user_id, :users)
  end

  def self.down
    drop_table :votes
  end
end
