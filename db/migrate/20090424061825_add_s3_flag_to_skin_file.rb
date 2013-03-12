class AddS3FlagToSkinFile < ActiveRecord::Migration
  def self.up
    add_column :skins, :file_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :skins, :file_in_s3
  end
end
