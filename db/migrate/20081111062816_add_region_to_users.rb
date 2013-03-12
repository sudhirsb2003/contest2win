class AddRegionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :region_id, :integer
    execute %{update users set region_id = (select id from regions where name = users.country)}
    execute %{update users set region_id = 1 where region_id is null}
  end

  def self.down
    remove_column :users, :region_id
  end
end
