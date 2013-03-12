class AddSpanToContestPrize < ActiveRecord::Migration
  def self.up
    remove_column :contest_prizes, :date
    add_column :contest_prizes, :from_date, :date, :null => false
    add_column :contest_prizes, :to_date, :date, :null => false
  end

  def self.down
    add_column :contest_prizes, :date, :date
    remove_column :contest_prizes, :from_date
    remove_column :contest_prizes, :to_date
  end
end
