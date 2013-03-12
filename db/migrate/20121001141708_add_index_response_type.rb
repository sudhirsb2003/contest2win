class AddIndexResponseType < ActiveRecord::Migration
  def self.up
    add_index :responses, :type
  end

  def self.down
    remove_index :responses, :type
  end
end
