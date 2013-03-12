class AddLoyaltyFlagToCreditTrans < ActiveRecord::Migration
  def self.up
    remove_column :credit_transactions, :sign
    add_column :credit_transactions, :loyalty_points, :boolean, :default => false, :null => false
    add_index :credit_transactions, :loyalty_points
  end

  def self.down
    add_column :credit_transactions, :sign, :integer
    remove_column :credit_transactions, :loyalty_points
  end
end
