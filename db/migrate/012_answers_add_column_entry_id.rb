class AnswersAddColumnEntryId < ActiveRecord::Migration
  def self.up
    add_column :answers, :entry_id, :integer
    add_index :answers, :entry_id
  end

  def self.down
    remove_index :answers, :entry_id
    remove_column :answers, :entry_id
  end
end
