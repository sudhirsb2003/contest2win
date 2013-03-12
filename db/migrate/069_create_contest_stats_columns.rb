class CreateContestStatsColumns < ActiveRecord::Migration
  def self.up
    add_column :contests, :played, :integer, :null => false, :default => 0
    add_index :contests, :played
    add_column :contests, :favourited, :integer, :null => false, :default => 0
    add_index :contests, :favourited
    add_column :contests, :net_votes, :integer, :null => false, :default => 0
    add_index :contests, :net_votes
    add_column :contests, :stats_updated_on, :datetime, :null => false, :default => '1970-01-01'
  end

  def self.down
    remove_column :contests, :played
    remove_column :contests, :favourited
    remove_column :contests, :net_votes
    remove_column :contests, :stats_updated_on
  end
end
