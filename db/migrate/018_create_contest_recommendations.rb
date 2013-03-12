require 'migration_helpers'

class CreateContestRecommendations < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :contest_recommendations do |t|
      t.column "from_email_address",          :string,   :limit => 255,         :null => false
      t.column "from_name",                   :string,   :limit => 30,         :null => false
      t.column "to_email_addresses",           :string,   :limit => 255,         :null => false
      t.column "user_id",                :integer,                         :null => true
      t.column "contest_id",             :integer,                         :null => false
      t.column "message",                :text,                            :null => false
      t.column "created_on",             :datetime,                        :null => false
    end
    add_index :contest_recommendations, :contest_id
    add_index :contest_recommendations, :user_id
    add_index :contest_recommendations, :created_on
    foreign_key(:contest_recommendations, :user_id, :users, false)
    foreign_key(:contest_recommendations, :contest_id, :contests, false)
  end

  def self.down
    drop_table :contest_recommendations
  end
end
