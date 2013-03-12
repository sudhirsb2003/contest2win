class AddLoginAttemptsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :login_attempts, :integer
  end

  def self.down
    remove_column :users, :login_attempts
  end
end
