class Ranking < ActiveRecord::Base
  DURATIONS = %w(daily weekly monthly annual)

  belongs_to :user

  named_scope :top, lambda{|leaderboard, limit| { :conditions => ["leaderboard = ?", leaderboard], :limit => limit, :order => 'rank asc' } }

  class << self
    def calculate_all
      DURATIONS.each do |duration|
        calculate(duration)
      end
    end

    def calculate(duration)
      leaderboard, lower_limit, upper_limit = case duration.to_sym
        when :daily then [duration + '_' + 1.day.ago.strftime('%d_%m_%Y'), 1.day.ago.beginning_of_day, 1.day.ago.end_of_day]
        when :weekly then [duration + '_' + 1.day.ago.strftime('%W_%Y'), 1.day.ago.beginning_of_week, 1.day.ago.end_of_day]
        when :monthly then [duration + '_' + 1.day.ago.strftime('%m_%Y'), 1.day.ago.beginning_of_month, 1.day.ago.end_of_day]
        when :annual then [duration + '_' + 1.day.ago.strftime('%Y'), 1.day.ago.beginning_of_year, 1.day.ago.end_of_day]
      end
      query = <<-SQL
        delete from rankings where leaderboard = '#{leaderboard}';
        create temp table #{leaderboard}_scores as (
          select user_id, sum(amount) as score from credit_transactions where amount > 0 and created_on between '#{lower_limit.to_s(:db)}' AND '#{upper_limit.to_s(:db)}' group by user_id
        );
        insert into rankings (user_id, leaderboard, rank, score, created_at, updated_at) (
          select user_id, '#{leaderboard}', (select 1 + count(l.*) from #{leaderboard}_scores l where score > #{leaderboard}_scores.score), score, now(), now() from #{leaderboard}_scores
        );
        drop table #{leaderboard}_scores;
      SQL
      transaction do
        connection.execute query
      end
    end
  end
end
