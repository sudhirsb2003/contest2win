class AddAdAccountFlagToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :can_have_ad_account, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :can_have_ad_account
  end
end
