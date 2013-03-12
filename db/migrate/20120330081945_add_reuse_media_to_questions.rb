class AddReuseMediaToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :reuse_previous_media, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :questions, :reuse_previous_media
  end
end
