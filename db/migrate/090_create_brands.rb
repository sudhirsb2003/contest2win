class CreateBrands < ActiveRecord::Migration
  def self.up
    create_table :brands do |t|
      t.column "name",          :string,   :limit => 100,                       :null => false
      t.column "logo",          :string, :null => false
      t.column "expired",       :boolean, :null => false, :default => false
      t.column "created_on",        :datetime,                                     :null => false
      t.column "updated_on",        :datetime,                                     :null => false
    end
    add_index :brands, :name, :unique => true
  end

  def self.down
    drop_table :brands
  end
end
