class AddFeaturedToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :featured, :boolean, :null => false, :default => false
    add_index "contests", :featured
  end

  def self.down
  end
end
