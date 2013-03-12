class ChangeDefaultOfOnlyAdminFlagInSkin < ActiveRecord::Migration
  def self.up
    execute %{alter table skins alter column only_admin set default false}
  end

  def self.down
  end
end
