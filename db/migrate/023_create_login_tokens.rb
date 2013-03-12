require 'migration_helpers'

class CreateLoginTokens < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :login_tokens do |t|
      t.column "user_id",    :integer,            :null => false
      t.column "token",      :text,               :null => false, :size => 32
      t.column "created_on", :datetime,           :null => false
    end
    add_index "login_tokens", ["user_id"]
    add_index "login_tokens", ["token"]
    foreign_key(:login_tokens, :user_id, :users)
  end

  def self.down
    drop_table :login_tokens
  end
end
