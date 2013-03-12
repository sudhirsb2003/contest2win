class AddOnlyAdminFlagToSkins < ActiveRecord::Migration
  def self.up
    add_column :skins, :only_admin, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :skins, :only_admin
  end
end
