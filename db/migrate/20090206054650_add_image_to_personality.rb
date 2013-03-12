class AddImageToPersonality < ActiveRecord::Migration
  def self.up
    add_column :personalities, :image, :string
    add_column :personalities, :image_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :personalities, :image
    remove_column :personalities, :image_in_s3
  end
end
