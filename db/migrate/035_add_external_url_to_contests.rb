class AddExternalUrlToContests < ActiveRecord::Migration
  def self.up
    add_column :contests, :external_url, :string
  end

  def self.down
    remove_column :contests, :external_url
  end
end
