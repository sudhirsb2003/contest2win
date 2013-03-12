class AdsenseCode < ActiveRecord::Migration
  def self.up
    rename_column :adsense_accounts, :code, :code_300x250
    add_column :adsense_accounts, :code_728x90, :text
  end

  def self.down
    rename_column :adsense_accounts, :code_300x250, :code
    remove_column :adsense_accounts, :code_728x90
  end
end
