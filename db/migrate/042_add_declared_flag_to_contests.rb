class AddDeclaredFlagToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :declared, :boolean, {:default => false}
    add_index :contests, :declared
    Contest.find(:all).each {|c| c.update_attribute(:declared, false)}
  end

  def self.down
    remove_column :contests, :declared
  end
end
