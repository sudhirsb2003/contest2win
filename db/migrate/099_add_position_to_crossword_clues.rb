class AddPositionToCrosswordClues < ActiveRecord::Migration
  def self.up
    add_column :crossword_clues, :position, :integer
  end

  def self.down
    remove_column :crossword_clues, :position
  end
end
