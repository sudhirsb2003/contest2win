class AddRatingToAnswers < ActiveRecord::Migration
  def self.up
    add_column :answers, :rating, :integer
  end

  def self.down
    remove_column :answers, :rating
  end
end
