class ModifyRecommendationFKs < ActiveRecord::Migration
  def self.up
    execute %{alter table contest_recommendations drop constraint fk_contest_recommendations_contest_id}
    execute %{alter table contest_recommendations add constraint fk_contest_recommendations_contest_id FOREIGN KEY (contest_id) REFERENCES contests(id) on delete cascade on update cascade}
  end

  def self.down
  end
end
