class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.column "name",        :string,   :limit => 30, :null => false
      t.column "slug",        :string,   :limit => 30, :null => false
      t.column "description", :string,                 :null => false
      t.column "created_on",  :datetime,               :null => false
      t.column "updated_on",  :datetime,               :null => false
    end
    add_index "categories", ["name"], :unique => true
    add_index "categories", ["slug"], :unique => true
    Category.create!(:name => 'Sports', :slug => 'sports', :description => 'Sports')
  end

  def self.down
    drop_table :categories
  end
end
