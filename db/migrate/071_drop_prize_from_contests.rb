class DropPrizeFromContests < ActiveRecord::Migration
  def self.up
    remove_column :contests, :declared
  end

  def self.down
    add_column :contests, :declared, :boolean
  end
end
