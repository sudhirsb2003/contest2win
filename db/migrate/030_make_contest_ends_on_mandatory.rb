class MakeContestEndsOnMandatory < ActiveRecord::Migration
  def self.up
    execute %{update contests set ends_on = now() where ends_on is null}
    execute %{alter table contests alter column ends_on set not null}
  end

  def self.down
  end
end
