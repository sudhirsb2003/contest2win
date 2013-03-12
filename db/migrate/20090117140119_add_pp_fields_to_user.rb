class AddPpFieldsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :net_pp_earned, :integer, :default => 0, :null => false
    add_column :users, :last_pp_earned, :integer, :default => 0, :null => false
    add_column :users, :pp_calculated_at, :datetime
    execute %{update users set net_pp_earned = (select sum(amount) from credit_transactions where user_id = users.id and loyalty_points = true)}
  end

  def self.down
    remove_column :users, :net_pp_earned
    remove_column :users, :last_pp_earned
    remove_column :users, :pp_calculated_at
  end
end
