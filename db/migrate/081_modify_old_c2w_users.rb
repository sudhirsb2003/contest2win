class ModifyOldC2wUsers < ActiveRecord::Migration
  def self.up
    remove_column :old_c2w_users, :day_counter
    remove_column :old_c2w_users, :reg_site
    remove_column :old_c2w_users, :points_2
  end

  def self.down
    add_column :old_c2w_users, :day_counter, :string
    add_column :old_c2w_users, :reg_site, :string
    add_column :old_c2w_users, :points_2, :string
  end
end
