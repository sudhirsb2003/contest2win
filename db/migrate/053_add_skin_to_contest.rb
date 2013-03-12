require 'migration_helpers'

class AddSkinToContest < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    add_column :contests, :skin_id, :integer
    add_index :contests, :skin_id
    foreign_key(:contests, :skin_id, :skins, false)
  end

  def self.down
    remove_column :contests, :skin_id
  end
end
