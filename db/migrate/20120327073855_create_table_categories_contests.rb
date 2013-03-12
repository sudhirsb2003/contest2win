class CreateTableCategoriesContests < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :categories_contests, :id => false do |t|
      t.integer :category_id, :null => false
      t.integer :contest_id, :null => false
    end
    add_index :categories_contests, [:category_id, :contest_id], :unique => true
    foreign_key(:categories_contests, :category_id, :categories)
    add_index :categories_contests, :contest_id
    foreign_key(:categories_contests, :contest_id, :contests)

  end

  def self.down
    drop_table :categories_contests
  end
end
