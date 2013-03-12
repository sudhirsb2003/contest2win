class DropIndexResponsesUpdatedOn < ActiveRecord::Migration
  def self.up
    remove_index(:responses, :updated_on) #rescue nil
    #remove_index(:responses, :created_on) #rescue nil
  end

  def self.down
    add_index(:responses, :updated_on) #rescue nil
    #add_index(:responses, :created_on) #rescue nil
  end
end
