class CreateUserActivationCodes < ActiveRecord::Migration
  def self.up
    create_table :user_activation_codes do |t|
      t.integer :user_id, :null => false
      t.string :code, :null => false
    end
    add_index :user_activation_codes, :user_id
  end

  def self.down
    drop_table :user_activation_codes
  end
end
