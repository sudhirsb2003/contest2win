class CreateReferrals < ActiveRecord::Migration
  def self.up
    create_table :referrals do |t|
      t.integer :referrer_id
      t.integer :referred_id
      t.string :referred_username
      t.datetime :created_on
      t.datetime :pp_threshold_reached_on
      t.datetime :creation_threshold_reached_on
    end
    add_index :referrals, :referrer_id
    add_index :referrals, :referred_id
    add_index :referrals, :pp_threshold_reached_on
    add_index :referrals, :creation_threshold_reached_on
    add_index :referrals, :created_on
  end

  def self.down
    drop_table :referrals
  end
end
