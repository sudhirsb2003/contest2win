class IncreaseContestDescription < ActiveRecord::Migration
  def self.up
    change_column :contests, :description, :string, :limit => 350
  end

  def self.down
  end
end
