class AddPaypalAccountIdToDispatch < ActiveRecord::Migration
  def self.up
    add_column :dispatches, :paypal_account_id, :string
  end

  def self.down
    remove_column :dispatches, :paypal_account_id
  end
end
