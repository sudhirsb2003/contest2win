class CreatePendingDeletions < ActiveRecord::Migration
  def self.up
    create_table :pending_deletions do |t|
      t.string :key, :null => false
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :pending_deletions
  end
end
