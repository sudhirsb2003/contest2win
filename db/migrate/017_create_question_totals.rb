class CreateQuestionTotals < ActiveRecord::Migration
  def self.up
    execute %{create or replace view question_totals as
    select c.id, count(q.*) as num_questions from contests c left outer join questions q on q.contest_id = c.id
    group by c.id}
  end

  def self.down
    execute %{drop view question_totals}
  end
end
