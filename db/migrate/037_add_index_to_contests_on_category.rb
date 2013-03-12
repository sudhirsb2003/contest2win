class AddIndexToContestsOnCategory < ActiveRecord::Migration
  def self.up
    add_index :contests, :category_id
  end

  def self.down
    remove_index :contests, :category_id
  end
end
