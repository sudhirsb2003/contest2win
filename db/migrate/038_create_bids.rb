class CreateBids < ActiveRecord::Migration
  def self.up
    create_table :bids do |t|
      t.column "k3b_id", :integer, :null => false
      t.column "user_id", :integer, :null => false
      t.column "toppled_by_id", :integer
      t.column "value", :float, :null => false
      t.column "created_on", :datetime, :null => false
      t.column "updated_on", :datetime, :null => false
    end
    add_index :bids, [:user_id, :k3b_id]
    add_index :bids, [:k3b_id, :value], :unique => true
  end

  def self.down
    drop_table :bids
  end
end
