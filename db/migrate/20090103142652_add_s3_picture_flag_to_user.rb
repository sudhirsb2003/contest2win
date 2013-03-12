class AddS3PictureFlagToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :picture_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :picture_in_s3
  end
end
