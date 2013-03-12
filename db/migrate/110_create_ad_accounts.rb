require 'migration_helpers'

class CreateAdAccounts < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :ad_accounts do |t|
      t.column "user_id",                   :integer,                                       :null => false
      t.column :publisher_id,               :string, :null => false
      t.column :channel_id,                  :string
    end
    foreign_key(:ad_accounts, :user_id, :users, true)
  end

  def self.down
    drop_table :ad_accounts
  end
end
