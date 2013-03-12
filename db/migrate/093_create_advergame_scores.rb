require 'migration_helpers'

class CreateAdvergameScores < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :advergame_scores do |t|
      t.column "id",        :integer,                     :null => false
      t.column "response_id",        :integer,                     :null => false
      t.column "contest_id", :integer
      t.column "score",             :integer,  :default => 0
      t.column "created_on",         :datetime,                    :null => false

    end

    add_index "advergame_scores", ["response_id"]

 
    foreign_key(:advergame_scores, :response_id, :responses)
    foreign_key(:advergame_scores, :contest_id, :contests)

  end

  def self.down
    drop_table :advergame_scores
  end
end
