class FixBettingLimit < ActiveRecord::Migration
  def self.up
    execute %{update questions set betting_limit = 200 from contests where contests.id = questions.contest_id and contests.type = 'Prediction'}
  end

  def self.down
  end
end
