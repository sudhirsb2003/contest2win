class FixOldC2wUserIndexes < ActiveRecord::Migration
  def self.up
    remove_index :old_c2w_users, :email
    remove_index :old_c2w_users, :userid
    execute %{create INDEX index_old_c2w_users_on_email on old_c2w_users (lower(email));}
    execute %{create INDEX index_old_c2w_users_on_userid on old_c2w_users (lower(userid));}
  end

  def self.down
  end
end
