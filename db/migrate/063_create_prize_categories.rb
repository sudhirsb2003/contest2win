require 'migration_helpers'

class CreatePrizeCategories < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :prize_categories do |t|
      t.column 'name', :string, :limit => 30, :null => false
    end
    add_index :prize_categories, [:name]

    create_table :prize_categories_prizes, :id => false do |t|
      t.column 'category_id', :integer, :null => false
      t.column 'prize_id', :integer, :null => false
    end
    add_index :prize_categories_prizes, [:prize_id]
    add_index :prize_categories_prizes, [:category_id]
    foreign_key(:prize_categories_prizes, :prize_id, :prizes)
    foreign_key(:prize_categories_prizes, :category_id, :prize_categories)

    
    ['CDs & DVDs','Credits','Electronics','Gift Vouchers','Other Cool Stuff','T-Shirts','Cameras','Mobile Phones',
      'Music Players', 'Video Games', 'PC Accessories','Watches'].each {|c|
      PrizeCategory.create(:name => c)
    }
  end

  def self.down
    drop_table :prize_categories_prizes
    drop_table :prize_categories
  end
end
