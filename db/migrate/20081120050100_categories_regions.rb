require 'migration_helpers'

class CategoriesRegions < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :categories_regions, :id => false do |t|
      t.integer :category_id, :null => false
      t.integer :region_id, :null => false
    end
    add_index :categories_regions, [:category_id, :region_id], :unique => true
    foreign_key(:categories_regions, :category_id, :categories)
    add_index :categories_regions, :region_id
    foreign_key(:categories_regions, :region_id, :regions)

    execute %{insert into categories_regions select id, 2 from categories}
  end

  def self.down
    drop_table :categories_regions 
  end
end
