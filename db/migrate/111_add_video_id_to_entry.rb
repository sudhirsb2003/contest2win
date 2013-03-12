class AddVideoIdToEntry < ActiveRecord::Migration
  def self.up
    add_column :entries, :video_id, :integer
    add_index :entries, :video_id
  end

  def self.down
    remove_column :entries, :video_id
  end
end
