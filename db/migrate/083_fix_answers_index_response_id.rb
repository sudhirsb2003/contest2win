class FixAnswersIndexResponseId < ActiveRecord::Migration
  def self.up
    execute %{drop index index_answers_on_response_id_and_correct}
    execute %{create index index_answers_on_response_id on answers(response_id)}
  end

  def self.down
    execute %{drop index index_answers_on_response_id}
    execute %{create index index_answers_on_response_id_and_correct on answers(response_id)}
  end
end
