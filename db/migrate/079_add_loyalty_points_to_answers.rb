class AddLoyaltyPointsToAnswers < ActiveRecord::Migration
  def self.up
    add_column :answers, :loyalty_points, :integer
    add_index :answers, :loyalty_points
  end

  def self.down
    remove_column :answers, :loyalty_points
  end
end
