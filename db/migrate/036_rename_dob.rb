class RenameDob < ActiveRecord::Migration
  def self.up
    execute %{alter table users rename column dob to date_of_birth}
  end

  def self.down
    execute %{alter table questions rename column date_of_birth to dob}
  end
end
