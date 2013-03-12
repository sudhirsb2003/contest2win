class AddIndexOnAnswersCreatedOn < ActiveRecord::Migration
  def self.up
    add_index :answers, :created_on
    add_index :answers, :points
  end

  def self.down
    remove_index :answers, :created_on
    #remove_index :answers, :points
  end
end
