class AddS3FlagToEntries < ActiveRecord::Migration
  def self.up
    add_column :entries, :image_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :entries, :image_in_s3
  end
end
