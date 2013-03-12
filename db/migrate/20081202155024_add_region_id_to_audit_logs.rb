class AddRegionIdToAuditLogs < ActiveRecord::Migration
  def self.up
    add_column :audit_logs, :region_id, :integer
  end

  def self.down
    remove_column :audit_logs, :region_id
  end
end
