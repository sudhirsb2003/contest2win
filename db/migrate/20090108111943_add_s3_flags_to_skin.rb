class AddS3FlagsToSkin < ActiveRecord::Migration
  def self.up
    add_column :skins, :image_in_s3, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :skins, :image_in_s3
  end
end
