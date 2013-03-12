class MakeAswersUnique < ActiveRecord::Migration
  def self.up
    add_index :answers, [:response_id, :question_id], :unique => true
  end

  def self.down
    remove_index :answers, [:response_id, :question_id]
  end
end
