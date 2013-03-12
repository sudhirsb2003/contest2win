class AddBrandUrlToContests < ActiveRecord::Migration
  def self.up
	 add_column :contests, :brand_url, :string
  end

  def self.down
	remove_column :contests, :brand_url
  end
end
