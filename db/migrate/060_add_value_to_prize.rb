class AddValueToPrize < ActiveRecord::Migration
  def self.up
    add_column :prizes, :value, :float
    add_column :prizes, :tds, :float
    add_column :prizes, :special_note, :text
    add_column :prizes, :item_type, :string # can be Credit/Object
    add_column :prizes, :thumbnail, :string
  end

  def self.down
    remove_column :prizes, :value
    remove_column :prizes, :tds
    remove_column :prizes, :special_note
    remove_column :prizes, :item_type
    remove_column :prizes, :thumbnail
  end
end
