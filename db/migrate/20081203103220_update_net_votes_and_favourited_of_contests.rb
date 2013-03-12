class UpdateNetVotesAndFavouritedOfContests < ActiveRecord::Migration
  def self.up
    execute %{update contests set net_votes = (select count(id) from votes where voteable_id=contests.id and points > 0), favourited=(select count(id) from favourites where contest_id=contests.id)}
  end

  def self.down
  end
end
