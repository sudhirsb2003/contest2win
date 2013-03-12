class AddAnswersCountToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :answers_count, :integer, :null => false, :default => 0
    execute %{update responses set answers_count = (select count(answers) from answers where answers.response_id = responses.id)}
  end

  def self.down
  end
end
