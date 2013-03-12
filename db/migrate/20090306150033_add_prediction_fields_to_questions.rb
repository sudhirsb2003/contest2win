class AddPredictionFieldsToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :ends_on, :datetime
    add_column :questions, :betting_status, :integer
    add_index :questions, :betting_status
  end

  def self.down
    remove_column :questions, :ends_on
    remove_column :questions, :betting_status
  end
end
