class AddTotalRating2Questions < ActiveRecord::Migration
  def self.up
    add_column :questions, :total_rating, :integer, :default => 0
  end

  def self.down
    remove_column :questions, :total_rating
  end
end
