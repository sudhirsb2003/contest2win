class AddIndexOnResponsesScore < ActiveRecord::Migration
  def self.up
    add_index :responses, :score
  end

  def self.down
    remove_index :responses, :score
  end
end
