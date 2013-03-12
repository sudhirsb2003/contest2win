require 'migration_helpers'

class CreateQuestions < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :questions do |t|
      t.column "contest_id", :integer,                                        :null => false
      t.column "user_id",    :integer,                                        :null => false
      t.column "question",   :string,                                         :null => false
      t.column "status",     :integer,   :default => Question::STATUS_APPROVAL_PENDING,  :null => false
      t.column "media",      :string
      t.column "image",      :string
      t.column "created_on", :datetime,                                       :null => false
      t.column "updated_on", :datetime,                                       :null => false
  end

  add_index "questions", ["contest_id"]
  add_index "questions", ["user_id"]
  add_index "questions", ["status"]
  foreign_key(:questions, :contest_id, :contests)
  foreign_key(:questions, :user_id, :users)

  end

  def self.down
    drop_table :questions
  end
end
