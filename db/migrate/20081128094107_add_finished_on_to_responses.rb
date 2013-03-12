class AddFinishedOnToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :finished_on, :datetime, :default => 'now()'
  end

  def self.down
    remove_column :responses, :finished_on
  end
end
