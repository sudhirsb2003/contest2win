class AddCountryToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :country, :string, :null => false, :default => 'India'
  end

  def self.down
    remove_column :users, :country
  end
end
