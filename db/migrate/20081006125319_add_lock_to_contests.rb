class AddLockToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :locked, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :contests, :locked
  end
end
