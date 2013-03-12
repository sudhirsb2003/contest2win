class AddHintToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :hint, :string
  end

  def self.down
    remove_column :questions, :hint
  end
end
