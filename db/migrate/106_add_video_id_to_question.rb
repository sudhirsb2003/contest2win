class AddVideoIdToQuestion < ActiveRecord::Migration
  def self.up
    add_column :questions, :video_id, :integer
    add_index :questions, :video_id
  end

  def self.down
    remove_column :questions, :video_id
  end
end
