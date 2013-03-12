class AddIndexesOnContests < ActiveRecord::Migration
  def self.up
    add_index :contests, [:starts_on, :ends_on]
    add_index :users, :status
  end

  def self.down
  end
end
