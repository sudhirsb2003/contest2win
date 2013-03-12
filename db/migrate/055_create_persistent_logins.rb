class CreatePersistentLogins < ActiveRecord::Migration
  def self.up
    create_table :persistent_logins do |t|
      t.column :uid, :string, :null => false
      t.column :user_id, :integer, :null => false
      t.column :created_on, :datetime, :null => false
    end
    add_index :persistent_logins, :uid, :name => "uid"
    add_index :persistent_logins, :created_on, :name => "created_on"    
  end

  def self.down
    drop_table :persistent_logins
  end
end
