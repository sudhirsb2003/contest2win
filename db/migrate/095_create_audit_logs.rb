class CreateAuditLogs < ActiveRecord::Migration
  def self.up
    create_table :audit_logs do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :integer
      t.column :activity, :string
      t.column :created_on, :datetime
    end
    add_index :audit_logs, :created_on
    add_index :audit_logs, :auditable_id
    add_index :audit_logs, :user_id
  end

  def self.down
    drop_table :audit_logs
  end
end
