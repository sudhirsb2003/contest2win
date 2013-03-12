class AddPoints2Entries < ActiveRecord::Migration
  def self.up
    add_column :entries, :total_points, :integer, :default => 0
  end

  def self.down
    remove_column :entries, :total_points
  end
end
