class AddStatusToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :status, :integer
    add_index :comments, :status
  end

  def self.down
    remove_column :comments, :status
  end
end
