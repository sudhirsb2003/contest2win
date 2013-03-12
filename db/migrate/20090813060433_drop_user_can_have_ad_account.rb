class DropUserCanHaveAdAccount < ActiveRecord::Migration
  def self.up
    remove_column :users, :can_have_ad_account
  end

  def self.down
    add_column :users, :can_have_ad_account, :boolean
  end
end
