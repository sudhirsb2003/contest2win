class AddCampaignIdToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :campaign_id, :integer
    add_index :contests, :campaign_id
  end

  def self.down
    remove_column :contests, :campaign_id
  end
end
