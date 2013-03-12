class CreateCredits < ActiveRecord::Migration
  def self.up
    create_table :credit_transactions do |t|
      t.column 'user_id', :integer, :null => false
      t.column 'amount', :float, :null => false
      t.column 'sign', :integer, :null => false, :default => 1 # can be +1 or -1 for Cr or Db
      t.column 'description', :string, :null => false
      t.column 'created_on', :datetime, :null => false
    end
    add_index :credit_transactions, :user_id
    add_index :credit_transactions, :created_on
  end

  def self.down
    drop_table :credit_transactions
  end
end
