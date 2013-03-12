class DeleteUnusedContests < ActiveRecord::Migration
  def self.up
    execute "update contests set status = #{Contest::STATUS_DELETED} where type in ('RateMe','Faceoff','Poll','Twister', 'Prediction')"
  end

  def self.down
  end
end
