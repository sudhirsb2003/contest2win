require 'migration_helpers'

class Tags < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :tags, :force => true do |t|
      t.column :name, :string
    end
    add_index "tags", ["name"], :unique => true

    create_table :taggings, :force => true do |t|
      t.column :tag_id, :integer
      t.column :taggable_id, :integer
      t.column :taggable_type, :string
      t.column :created_at, :datetime
    end
    add_index :taggings, "tag_id"
    add_index :taggings, "taggable_id"
    add_index :taggings, :taggable_type
    foreign_key(:taggings, :tag_id, :tags)
  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
