class AddFriendsCounterToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :number_of_friends, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :number_of_friends
  end
end
