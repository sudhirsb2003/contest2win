class AddColumnUpdatedOnToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :updated_on, :datetime, :null => false, :default => Time.now
    add_index "responses", ["updated_on"]
    remove_index "responses", ["created_on"]
  end

  def self.down
    remove_column :responses, :updated_on
  end
end
