require 'migration_helpers'

class CreateVideos < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :videos do |t|
      t.column :title, :string, :null => false
      t.column :original_file, :string, :null => false
      t.column :stream_file, :string
      t.column :image, :string
      t.column :status, :integer, :null => false, :default => Video::STATUS_CONVERSION_PENDNG
      t.column :created_by_id, :integer, :null => false
      t.column :created_on, :datetime, :null => false
      t.column :updated_on, :datetime, :null => false
      t.column :shared, :boolean, :null => false, :default => false
    end
    add_index :videos, :status
    add_index :videos, :created_on
    add_index :videos, :created_by_id
    foreign_key(:videos, :created_by_id, :users, false)
  end

  def self.down
    drop_table :videos
  end
end
