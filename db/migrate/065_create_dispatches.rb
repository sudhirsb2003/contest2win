class CreateDispatches < ActiveRecord::Migration
  def self.up
    create_table :dispatches do |t|
      t.column 'prize_id', :integer, :null => false
      t.column 'user_id', :integer, :null => false
      t.column 'address_line_1', :string, :null => false
      t.column 'address_line_2', :string
      t.column 'city', :string, :null => false
      t.column 'pin_code', :string, :null => false
      t.column 'state', :string, :null => false
      t.column 'country', :string, :null => false
      t.column 'mobile_number', :string, :null => false
      t.column 'phone_number', :string, :null => false
      t.column 'short_listed_winner_id', :integer
      t.column 'credit_transaction_id', :integer
      t.column 'status', :integer, :null => false, :default => 0
      t.column 'cancelation_reason', :string
      t.column 'payment_type', :string
      t.column 'payment_number', :string
      t.column 'payment_amount', :float
      t.column 'payment_received_on', :datetime
      t.column 'payment_received_by_id', :integer
      t.column 'actioned_on', :datetime
      t.column 'actioned_by_id', :integer
      t.column 'created_on', :datetime, :null => false
    end
  end

  def self.down
    drop_table :dispatches
  end
end
