class AddGridSizeToCrosswords < ActiveRecord::Migration
  def self.up
    add_column :contests, :version_number, :string
    execute %{update contests set version_number = '2.13'}
  end

  def self.down
    remove_column :contests, :version_number
  end
end
