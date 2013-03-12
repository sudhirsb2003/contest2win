class CreateRankings < ActiveRecord::Migration
  def self.up
    create_table :rankings do |t|
      t.belongs_to :user, :null => false
      t.string :leaderboard, :null => false
      t.integer :rank, :null => false
      t.integer :score, :null => false

      t.timestamps
    end
    add_index :rankings, [:leaderboard, :user_id], :unique => true
    add_index :rankings, [:leaderboard, :rank]
  end

  def self.down
    drop_table :rankings
  end
end
