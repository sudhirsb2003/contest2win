class AddNumberOfUsersToPersonality < ActiveRecord::Migration
  def self.up
    add_column :personalities, :number_of_users, :integer, :default => 0
  end

  def self.down
    remove_column :personalities, :number_of_users
  end
end
