require 'migration_helpers'

class CreateContests < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :contests do |t|
      t.column "title",                     :string,   :limit => 100,                       :null => false
      t.column "description",               :string,                                        :null => false
      t.column "slug",                      :string,   :limit => 100,                       :null => false
      t.column "type",                      :string,                                        :null => false
      t.column "content_type",              :string,                  :default => "Text",   :null => false
      t.column "status",                    :integer,                 :default => Contest::STATUS_LIVE, :null => false
      t.column "others_can_submit_entries", :boolean,                 :default => true,     :null => false
      t.column "starts_on",                 :date,                                          :null => false
      t.column "ends_on",                   :date,                                          :null => false
      t.column "user_id",                   :integer,                                       :null => false
      t.column "category_id",               :integer,                 :default => 1,        :null => false
      t.column "created_on",                :datetime,                                      :null => false
      t.column "updated_on",                :datetime,                                      :null => false
    end
    add_index "contests", ["content_type"]
    add_index "contests", ["created_on"]
    add_index "contests", ["type"]
    add_index "contests", ["user_id"]
    add_index "contests", ["status"]
    foreign_key(:contests, :user_id, :users, false)
  end

  def self.down
    drop_table :contests
  end
end
