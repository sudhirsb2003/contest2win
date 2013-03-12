class AddRegionToBanners < ActiveRecord::Migration
  def self.up
    add_column :banners, :region_id, :integer
    execute %{update banners set region_id = (select id from regions where domain_prefix = 'in')}
  end

  def self.down
    remove_column :banners, :region_id
  end
end
