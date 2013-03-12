class AddRegionToPrizes < ActiveRecord::Migration
  def self.up
    add_column :prizes, :region_id, :integer
    add_index :prizes, :region_id
    execute %{update prizes set region_id = 2}
  end

  def self.down
    remove_column :prizes, :region_id
  end
end
