class CreateMostFavouritedTotals < ActiveRecord::Migration
  def self.up
    execute %{create or replace view favourite_totals as
    select c.id, count(f.*) as num_favourited from contests c left outer join favourites f on f.contest_id = c.id
    group by c.id}
  end

  def self.down
    execute %{drop view favourite_totals}
  end
end
