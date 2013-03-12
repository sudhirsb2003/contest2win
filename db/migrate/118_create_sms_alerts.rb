class CreateSmsAlerts < ActiveRecord::Migration
  def self.up
    create_table :sms_alerts do |t|
      t.integer     :user_id, :null => false
      t.string      :msisdn, :null => false
      t.string      :message
      t.integer     :attempts, :null => false, :default => 0
      t.integer     :status, :null => false, :default => SmsAlert::STATUS_PENDING
      t.string      :transaction_id
      t.datetime    :sent_on
      t.timestamps
    end
    add_index :sms_alerts, :status
  end

  def self.down
     drop_table :sms_alerts
  end
end
