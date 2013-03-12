require 'migration_helpers'

class CreateQuestionOptions < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :question_options do |t|
      t.column "question_id", :integer,                :null => false
      t.column "entry_id",    :integer
      t.column "position",    :integer, :default => 0, :null => false
      t.column "points",      :integer, :default => 0, :null => false
      t.column "text",        :string,                 :null => false
  end

  add_index "question_options", ["question_id"]
  foreign_key(:question_options, :question_id, :questions)

  end

  def self.down
    drop_table :question_options
  end
end
