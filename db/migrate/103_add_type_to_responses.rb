class AddTypeToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :type, :string, :default => 'Response', :null => false
  end

  def self.down
    remove_column :responses, :type
  end
end
