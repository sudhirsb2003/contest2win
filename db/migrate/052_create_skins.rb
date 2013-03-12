class CreateSkins < ActiveRecord::Migration
  def self.up
    create_table :skins do |t|
      t.column "name",          :string,   :limit => 30,                       :null => false
      t.column "description",   :text,                       :null => false
      t.column "contest_type",  :string,   :limit => 30,                       :null => false
      t.column "image",         :string
      t.column "file",          :string, :null => false
      t.column "expired",       :boolean,   :default => 'false', :null => false
      t.column "created_on",        :datetime,                                     :null => false
      t.column "updated_on",        :datetime,                                     :null => false
    end
    add_index :skins, :name, :unique => true
    add_index :skins, [:contest_type, :expired]
  end

  def self.down
    drop_table :skins
  end
end
