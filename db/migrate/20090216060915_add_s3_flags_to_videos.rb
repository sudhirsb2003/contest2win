class AddS3FlagsToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :stream_file_in_s3, :boolean, :default => false, :null => false
    add_column :videos, :image_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :videos, :stream_file_in_s3
    remove_column :videos, :image_in_s3
  end
end
