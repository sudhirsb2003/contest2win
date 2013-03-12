class FixResponseTypes < ActiveRecord::Migration
  def self.up
    execute %{UPDATE responses SET type = contests.type||'Response' from contests where contests.id = responses.contest_id and contests.type in ('Hangman','RateMe');}
  end

  def self.down
    #execute %{UPDATE responses SET type = 'Response' from contests where contests.id = responses.contest_id and contests.type = 'Hangman';}
  end
end
