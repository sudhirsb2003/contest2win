class LeaderboardsController < ApplicationController
  before_filter :login_required

  def show
    duration = params[:duration]
    raise ActiveRecord::RecordNotFound unless Ranking::DURATIONS.include?(duration)
    leaderboard = duration + '_' + (params[:key] || case duration.to_sym
      when :daily then 1.day.ago.strftime('%d_%m_%Y')
      when :weekly then 1.day.ago.strftime('%W_%Y')
      when :monthly then 1.day.ago.strftime('%m_%Y')
      when :annual then 1.day.ago.strftime('%Y')
    end)
    @rankings = Ranking.top(leaderboard, 20)
    @title = "#{duration.humanize} Leaderboard"
  end
end
