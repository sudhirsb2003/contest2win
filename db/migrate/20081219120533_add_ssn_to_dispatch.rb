class AddSsnToDispatch < ActiveRecord::Migration
  def self.up
    add_column :dispatches, :ssn, :string
  end

  def self.down
    remove_column :dispatches, :ssn
  end
end
