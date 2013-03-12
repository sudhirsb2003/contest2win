class AddContestIndexOnResponses < ActiveRecord::Migration
  def self.up
    add_index :responses, :contest_id
  end

  def self.down
  end
end
