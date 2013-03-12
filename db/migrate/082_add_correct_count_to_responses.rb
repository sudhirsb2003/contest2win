class AddCorrectCountToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :correct_answers_count, :integer, :default => 0, :null => false
    execute %{UPDATE responses set correct_answers_count = (select count(id) from answers where answers.response_id = responses.id and correct = true)}
    #execute %{alter table responses alter column correct_answers_count set default 0}
  end

  def self.down
    remove_column :responses, :correct_answers_count
  end
end
