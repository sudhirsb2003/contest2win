class CreateLoyaltyPointsLogs < ActiveRecord::Migration
  def self.up
    create_table :loyalty_points_logs do |t|
      t.datetime :ran_on
    end
  end

  def self.down
    drop_table :loyalty_points_logs
  end
end
