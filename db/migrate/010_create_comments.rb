require 'migration_helpers'

class CreateComments < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :comments do |t|
      t.column "title",          :string,   :limit => 50, :null => false
      t.column "message",        :text,                   :null => false
      t.column "commentable_id", :integer,                :null => false
      t.column "user_id",        :integer,                :null => false
      t.column "created_on",     :datetime,               :null => false
    end

    add_index "comments", ["commentable_id"]
    add_index "comments", ["created_on"]
    add_index "comments", ["user_id"]
    foreign_key(:comments, :user_id, :users)

  end

  def self.down
    drop_table :comments
  end
end
