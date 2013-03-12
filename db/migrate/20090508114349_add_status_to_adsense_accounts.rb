class AddStatusToAdsenseAccounts < ActiveRecord::Migration
  def self.up
    add_column :adsense_accounts, :approval_status, :string
    add_column :adsense_accounts, :association_status, :string
  end

  def self.down
    remove_column :adsense_accounts, :approval_status
    remove_column :adsense_accounts, :association_status
  end
end
