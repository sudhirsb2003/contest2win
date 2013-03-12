class AddForFieldsToCreditTransactions < ActiveRecord::Migration
  def self.up
    add_column :credit_transactions, :for_id, :integer
    add_column :credit_transactions, :for_type, :string
    add_index :credit_transactions, [:for_type, :for_id]
  end

  def self.down
    remove_column :credit_transactions, :for_id
    remove_column :credit_transactions, :for_type
  end
end
