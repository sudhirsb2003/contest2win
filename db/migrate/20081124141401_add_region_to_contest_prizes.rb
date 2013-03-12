class AddRegionToContestPrizes < ActiveRecord::Migration
  def self.up
    add_column :contest_prizes, :region_id, :integer
    add_index :contest_prizes, :region_id
    execute %{update contest_prizes set region_id = (select region_id from prizes where prizes.id = contest_prizes.prize_id)}
  end

  def self.down
    remove_column :contest_prizes, :region_id
  end
end
