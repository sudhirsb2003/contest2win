class AddPwdToOldC2WUser < ActiveRecord::Migration
  def self.up
    add_column :old_c2w_users, :password, :string
    add_column :old_c2w_users, :userid, :string

    add_index :old_c2w_users, [:email]
    add_index :old_c2w_users, [:userid]
    add_index :old_c2w_users, [:new_user_id]
  end

  def self.down
    remove_column :old_c2w_users, :password
    remove_column :old_c2w_users, :userid
  end
end
