class AddColumnViewLevelToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :view_level, :integer, :null => false, :default => Response::VIEW_LEVEL_ALL
  end

  def self.down
    remove_column :responses, :view_level
  end
end
