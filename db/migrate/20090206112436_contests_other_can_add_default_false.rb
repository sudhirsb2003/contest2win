class ContestsOtherCanAddDefaultFalse < ActiveRecord::Migration
  def self.up
    change_column :contests, :others_can_submit_entries, :boolean, :default => false
  end

  def self.down
    change_column :contests, :others_can_submit_entries, :boolean, :default => true
  end
end
