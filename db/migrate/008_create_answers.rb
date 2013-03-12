require 'migration_helpers'

class CreateAnswers < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :answers do |t|
      t.column "response_id",        :integer,                     :null => false
      t.column "question_id",        :integer,                     :null => false
      t.column "question_option_id", :integer
      t.column "points",             :integer,  :default => 0,     :null => false
      t.column "created_on",         :datetime,                    :null => false
      t.column "correct",            :boolean,  :default => false, :null => false
    end

    add_index "answers", ["question_id"]
    add_index "answers", ["question_option_id"]
    add_index "answers", ["response_id", "correct"]
    foreign_key(:answers, :question_id, :questions)
    foreign_key(:answers, :response_id, :responses)
    foreign_key(:answers, :question_option_id, :question_options)

  end

  def self.down
    drop_table :answers
  end
end
