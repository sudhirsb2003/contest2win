class AddColumnBettingLimitToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :betting_limit, :integer
  end

  def self.down
    remove_column :questions, :betting_limit
  end
end
