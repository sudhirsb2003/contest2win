class ChangeResponsesIndexOnUpdatedOnToCreatedOn < ActiveRecord::Migration
  def self.up
    remove_index :responses, :updated_on rescue nil
    add_index :responses, :created_on rescue nil
  end

  def self.down
  end
end
