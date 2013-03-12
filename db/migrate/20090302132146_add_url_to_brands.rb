class AddUrlToBrands < ActiveRecord::Migration
  def self.up
    add_column :brands, :url, :string
    execute %{update brands set url = (select brand_url from contests where contests.brand_id = brands.id limit 1)}
  end

  def self.down
    remove_column :brands, :url
  end
end
