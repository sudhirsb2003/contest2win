class AddNewsletterFlagToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :subscribe_to_newsletter, :boolean, :default => false
    add_index :users, :subscribe_to_newsletter
  end

  def self.down
    remove_column :users, :subscribe_to_newsletter
  end
end
