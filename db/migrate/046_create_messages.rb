require 'migration_helpers'

class CreateMessages < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :messages do |t|
      t.column 'body',          :text,                         :null => false
      t.column 'sender_id',          :integer,                         :null => false
      t.column 'receiver_id',          :integer,                         :null => false
      t.column 'created_on',        :datetime,                                     :null => false
    end
    add_index :messages, :sender_id
    add_index :messages, [:receiver_id, :created_on]
    foreign_key(:messages, 'sender_id', :users)
    foreign_key(:messages, 'receiver_id', :users)
  end

  def self.down
    drop_table :messages
  end
end
