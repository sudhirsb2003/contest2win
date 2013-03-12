class CreateCrosswords < ActiveRecord::Migration
  def self.up
    create_table :crosswords do |t|
    end
  end

  def self.down
    drop_table :crosswords
  end
end
