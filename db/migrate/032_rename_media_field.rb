class RenameMediaField < ActiveRecord::Migration
  def self.up
    execute %{alter table questions rename column media to video_url}
    execute %{alter table entries rename column media to video_url}
  end

  def self.down
  end
end
