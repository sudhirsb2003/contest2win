class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.string :name, :null => false
      t.string :value, :null => false
    end
    add_index :settings, :name, :unique => true
  end

  def self.down
    drop_table :settings
  end
end
