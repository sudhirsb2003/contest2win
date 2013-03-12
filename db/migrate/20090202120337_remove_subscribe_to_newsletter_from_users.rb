class RemoveSubscribeToNewsletterFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :subscribe_to_newsletter
  end

  def self.down
    add_column :users, :subscribe_to_newsletter, :boolean, :default => false
  end
end
