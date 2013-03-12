class AddCreditsToPrizes < ActiveRecord::Migration
  def self.up
    add_column :prizes, :credits, :float
  end

  def self.down
    remove_column :prizes, :credits
  end
end
