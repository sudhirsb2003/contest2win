class AddIndexesToQuestionOptions < ActiveRecord::Migration
  def self.up
    add_index :question_options, :entry_id
  end

  def self.down
    remove_index :question_options, :entry_id
  end
end
