class AddCampaingFieldsToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :campaign_type, :string
  end

  def self.down
    remove_column :contests, :campaign_type
  end
end
