require 'migration_helpers'

class CreateEntries < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :entries do |t|
      t.column "faceoff_id",  :integer,                                        :null => false
      t.column "user_id",     :integer,                                        :null => false
      t.column "title",       :string,                                         :null => false
      t.column "description", :text
      t.column "status",      :integer,   :default => Entry::STATUS_APPROVAL_PENDING,   :null => false
      t.column "media",       :string
      t.column "image",       :string
      t.column "created_on",  :datetime,                                       :null => false
    end

    add_index "entries", ["created_on"]
    add_index "entries", ["faceoff_id"]
    add_index "entries", ["status"]
    add_index "entries", ["user_id"]
    foreign_key(:entries, :user_id, :users)
    foreign_key(:entries, :faceoff_id, :contests)
  end

  def self.down
    drop_table :entries
  end
end
