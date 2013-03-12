class CreateIgnoredUsers < ActiveRecord::Migration
  def self.up
    create_table :ignored_users do |t|
      t.column "user_id",                   :integer,                                       :null => false
      t.column "ignored_user_id",           :integer,                                       :null => false
    end
    add_index :ignored_users, :user_id
    add_index :ignored_users, :ignored_user_id
  end

  def self.down
    drop_table :ignored_users
  end
end
