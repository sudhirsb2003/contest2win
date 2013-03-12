require 'migration_helpers'

class CreateUserPreferences < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :user_preferences do |t|
      t.integer :user_id, :null => false
      t.integer :preference_type, :null => false
    end
    add_index :user_preferences, :user_id
    foreign_key(:user_preferences, :user_id, :users)
    execute %{insert into user_preferences (user_id,preference_type) select id, #{UserPreference::PREFERENCE_TYPES[:no_newsletter]} from users where subscribe_to_newsletter = false}
  end

  def self.down
    drop_table :user_preferences
  end
end
