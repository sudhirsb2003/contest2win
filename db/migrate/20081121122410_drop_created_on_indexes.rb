class DropCreatedOnIndexes < ActiveRecord::Migration
  def self.up
    remove_index :contests, :created_on rescue nil
    remove_index :comments, :created_on rescue nil
    remove_index :entries, :created_on rescue nil
    remove_index :videos, :created_on rescue nil
    # persistent_login uses a weird index name
    execute %{drop index created_on} rescue nil
    remove_index :contest_recommendations, :created_on rescue nil
    remove_index :credit_transactions, :created_on rescue nil
  end

  def self.down
  end
end
