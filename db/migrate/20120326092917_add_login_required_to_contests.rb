class AddLoginRequiredToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :login_required, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :contests, :login_required
  end
end
