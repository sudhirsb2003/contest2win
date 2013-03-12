require 'migration_helpers'

class CreateRegions < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :regions do |t|
      t.string :name, :null => false
      t.string :domain_prefix, :null => false
    end
    add_index :regions, :domain_prefix, :unique => true
    Region.create!(:domain_prefix => 'www', :name => 'Worldwide')
    Region.create!(:domain_prefix => 'in', :name => 'India')
    Region.create!(:domain_prefix => 'us', :name => 'United States')

    create_table :contest_regions do |t|
      t.integer :contest_id, :null => false
      t.integer :region_id, :null => false
      t.boolean :featured
      t.boolean :loyalty_points_enabled
    end
    add_index :contest_regions, :contest_id
    foreign_key(:contest_regions, :contest_id, :contests)
    add_index :contest_regions, :region_id
    foreign_key(:contest_regions, :region_id, :regions)
    add_index :contest_regions, :featured
    add_index :contest_regions, :loyalty_points_enabled
    execute %{INSERT INTO contest_regions(contest_id,region_id, featured, loyalty_points_enabled) select id, 2, featured, loyalty_points_enabled from contests where contests.status = #{Contest::STATUS_LIVE}}
  end

  def self.down
    drop_table :contest_regions
    drop_table :regions
  end
end
