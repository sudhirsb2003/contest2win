class AddS3FlagToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :image_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :questions, :image_in_s3
  end
end
