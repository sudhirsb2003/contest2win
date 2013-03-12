class CampaignsController < ContestsController
  def play
    redirect_to contests_url(:controller => 'contests', :campaign_id => @contest.id, :action => :most_played)
  end
end

