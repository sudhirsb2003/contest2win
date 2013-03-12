require 'migration_helpers'

class LinkDispatchesToShortListedWinners < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    add_index 'dispatches', ["short_listed_winner_id"]
    foreign_key(:dispatches, :short_listed_winner_id, :short_listed_winners, false)
  end

  def self.down
  end
end
