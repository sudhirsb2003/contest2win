class RemoveAnswerFromQuestion < ActiveRecord::Migration
  def self.up
  	remove_column :questions ,:answer
  end

  def self.down
  	add_column :questions, :answer, :string
  end
end
