class AddS3FlagsToPrizes < ActiveRecord::Migration
  def self.up
    add_column :prizes, :thumbnail_in_s3, :boolean, :default => false, :null => false
    add_column :prizes, :image_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :prizes, :thumbnail_in_s3
    remove_column :prizes, :image_in_s3
  end
end
