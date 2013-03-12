require 'migration_helpers'

class AddCategoryConstraintOnContests < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    foreign_key(:contests, :category_id, :categories, false)
  end

  def self.down
  end
end
