class AddFbIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :fb_id, :bigint
    add_index :users, :fb_id
  end

  def self.down
    remove_column :users, :fb_id
  end
end
