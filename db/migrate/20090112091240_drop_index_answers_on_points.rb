class DropIndexAnswersOnPoints < ActiveRecord::Migration
  def self.up
    remove_index :answers, :points rescue nil
    remove_index :answers, :loyalty_points rescue nil
    remove_index :answers, :entry_id rescue nil
    remove_index :responses, :score rescue nil
    remove_index :responses, :old_response rescue nil
  end

  def self.down
  end
end
