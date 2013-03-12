class DelistTwisters < ActiveRecord::Migration
  def self.up
    execute %{update contests set status = 20120717 where status = #{Contest::STATUS_LIVE} and type = 'Twister' }
  end

  def self.down
    execute %{update contests set status = #{Contest::STATUS_LIVE} where status = 20120717 and type = 'Twister' }
  end
end
