class CommunityController < ApplicationController

  before_filter :set_time

  def summary
    @community_cache_key = "/community/summary/_time#{params[:time].hash}-#{Time.now.to_i/10.minutes.to_i}" # cache for 10 minutes    
    unless read_fragment(@community_cache_key)
      @best_creators = User.top_contest_creators.find(:all, :conditions => ['contests.created_on >= ?', @time], :limit => 8)
      @winners = ShortListedWinner.latest_winners.find(:all, :limit => 5, :conditions => ['short_listed_winners.created_on >= ?', @time])
      @recent_logins = User.find(:all, :conditions => ["last_logged_in_on >= now() - interval '1 day'"], :order => 'random()', :limit => 12)
    end
  end

  def best_creators
    @community_best_creators_cache_key = "/community/best_creators/#{params[:time].hash}-#{params[:page]||1}-#{Time.now.to_i/10.minutes.to_i}" # cache for 10 minutes
    unless read_fragment(@community_best_creators_cache_key)
      @best_creators = User.top_contest_creators.paginate(:conditions => ['contests.created_on >= ?', @time], :total_entries => User.top_contest_creators_count(@time),
          :page => params[:page], :per_page => 30)
    end  
  end

  def winners
    @community_winners_cache_key = "/community/summary/winners/#{params[:time].hash}-#{params[:page]||1}-#{Time.now.to_i/10.minutes.to_i}" # cache for 10 minutes
    unless read_fragment(@community_winners_cache_key)      
      @winners = ShortListedWinner.latest_winners.paginate(:page => params[:page], :per_page => 10, :conditions => ['short_listed_winners.created_on >= ?', @time])
    end
  end

  private
  def set_time	
    if params[:time] == 'Last 7 Days'
      @time = 7.days.ago
    else
      @time = 30.days.ago
      params[:time] = 'Last 30 Days'
    end  
  end
end
