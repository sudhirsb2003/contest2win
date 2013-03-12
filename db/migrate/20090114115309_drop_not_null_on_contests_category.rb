class DropNotNullOnContestsCategory < ActiveRecord::Migration
  def self.up
    change_column :contests, :category_id, :integer, :null => true
  end

  def self.down
    change_column :contests, :category_id, :integer, :null => false
  end
end
