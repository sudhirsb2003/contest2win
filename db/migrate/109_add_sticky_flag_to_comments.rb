class AddStickyFlagToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :sticky, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :comments, :sticky
  end
end
