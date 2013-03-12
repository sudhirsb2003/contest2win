class CreateBanners < ActiveRecord::Migration
  def self.up
    create_table :banners do |t|
      t.column :location, :string, :null => false
      t.column :code, :text, :null => false
      t.column :created_on, :datetime, :null => false
      t.column :updated_on, :datetime, :null => false
    end
  end

  def self.down
    drop_table :banners
  end
end
