require 'migration_helpers'

class CreateAdsenseAccounts < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :adsense_accounts do |t|
      t.integer :user_id, :null => false
      t.string :client_id, :null => false
      t.text :code
      t.string :email_address
      t.string :postal_code
      t.string :phone_hint
      t.string :account_type

      t.timestamps
    end
    add_index :adsense_accounts, :user_id
    foreign_key(:adsense_accounts, :user_id, :users, true)
  end

  def self.down
    drop_table :adsense_accounts
  end
end
