class AddS3FlagsToBrands < ActiveRecord::Migration
  def self.up
    add_column :brands, :logo_in_s3, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :brands, :logo_in_s3
  end
end
