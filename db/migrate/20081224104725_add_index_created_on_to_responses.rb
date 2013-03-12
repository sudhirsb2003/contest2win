class AddIndexCreatedOnToResponses < ActiveRecord::Migration
  def self.up
    add_index :responses, :updated_on
  end

  def self.down
    remove_index :responses, :updated_on
  end
end
