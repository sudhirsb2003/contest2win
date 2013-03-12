require 'migration_helpers'

class CreateCampaignContestTypes < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :campaign_contest_types do |t|
      t.integer :contest_id, :null => false
      t.string :contest_type, :null => false
      t.integer :skin_id, :null => false
    end
    add_index :campaign_contest_types, :contest_id
    foreign_key(:campaign_contest_types, :contest_id, :contests)
    add_index :campaign_contest_types, :skin_id
    foreign_key(:campaign_contest_types, :skin_id, :skins)
    add_index :campaign_contest_types, [:contest_id, :contest_type], :unique => true
  end

  def self.down
    drop_table :campaign_contest_types
  end
end
