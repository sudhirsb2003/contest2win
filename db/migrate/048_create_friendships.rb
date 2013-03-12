class CreateFriendships < ActiveRecord::Migration
  def self.up
    create_table :friendships do |t|
      t.column "user_id",                   :integer,                                       :null => false
      t.column "friend_id",                   :integer,                                       :null => false
    end
    add_index :friendships, :user_id
    add_index :friendships, :friend_id
  end

  def self.down
    drop_table :friendships
  end
end
