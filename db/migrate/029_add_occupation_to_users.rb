class AddOccupationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :occupation, :string
    execute %{update users set gender='Male'}
  end

  def self.down
  end
end
