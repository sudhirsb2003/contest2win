class AddExternalUrlToEntry < ActiveRecord::Migration
  def self.up
    add_column :entries, :external_video_url, :string
  end

  def self.down
    remove_column :entries, :external_video_url
  end
end
