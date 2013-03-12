class CreateResponseTotals < ActiveRecord::Migration
  def self.up
    execute %{create or replace view response_totals as
    select c.id, count(r.*) as num_responses from contests c left outer join responses r on r.contest_id = c.id
    group by c.id}
  end

  def self.down
    execute %{drop view response_totals}
  end

end
