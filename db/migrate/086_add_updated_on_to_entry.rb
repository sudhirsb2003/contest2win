class AddUpdatedOnToEntry < ActiveRecord::Migration
  def self.up
    add_column :entries, :updated_on, :datetime, :null => false, :default => 'now()'
  end

  def self.down
    remove_column :entries, :updated_on
  end
end
