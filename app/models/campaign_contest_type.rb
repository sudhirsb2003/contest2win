class CampaignContestType < ActiveRecord::Base
  after_save :update_contest_attributes

  private
  def update_contest_attributes
    Contest.update_all(['skin_id = ?', skin_id], ['campaign_id = ? and type = ?', contest_id, contest_type]) if skin_id_changed?
    true
  end
end
