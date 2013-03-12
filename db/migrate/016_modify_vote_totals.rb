class ModifyVoteTotals < ActiveRecord::Migration
  def self.up
    execute %{create or replace view vote_totals as
    select c.id, sum(case when v.points is null then 0 else v.points end) as points from contests c left outer join votes v on v.voteable_id = c.id
    group by c.id}
  end

  def self.down
  end
end
