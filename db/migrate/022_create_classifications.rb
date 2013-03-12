require 'migration_helpers'

class CreateClassifications < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :classifications do |t|
      t.column "minimum_score", :integer,            :null => false
      t.column "maximum_score", :integer,            :null => false
      t.column "description",   :text,               :null => false
      t.column "contest_id",    :integer,            :null => false
    end
    add_index "classifications", ["contest_id"]
    foreign_key(:classifications, :contest_id, :contests)
  end

  def self.down
    drop_table :classifications
  end
end
