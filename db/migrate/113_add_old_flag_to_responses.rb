class AddOldFlagToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :old_response, :boolean, :default => false, :null => false
    add_index :responses, :old_response
  end

  def self.down
    remove_column :responses, :old_response
  end
end
