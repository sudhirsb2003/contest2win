class CreateFavourites < ActiveRecord::Migration
  def self.up
    create_table :favourites do |t|
      t.column "user_id",         :integer,         :null => false
      t.column "contest_id",      :integer,         :null => false
    end
    add_index :favourites, :user_id
    add_index :favourites, :contest_id
  end

  def self.down
    drop_table :favourites
  end
end
