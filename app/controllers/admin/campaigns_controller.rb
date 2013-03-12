class Admin::CampaignsController < AdminController
  
  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new params[:campaign]
    @campaign.user = current_user
    @campaign.status = Campaign::STATUS_LIVE
    @campaign.region_ids = params[:regions]
    contest_types = params[:contest_types]
    contest_types.each_value do |contest_type|
      @campaign.contest_types.build(contest_type) unless contest_type[:skin_id].blank?
    end
    if @campaign.save
      return redirect_to admin_campaigns_path
    end
    render :action => :new
  end

  def edit
    @campaign = Campaign.find params[:id]
  end

  def update
    @campaign = Campaign.find params[:id]
    @campaign.attributes = params[:campaign]
    Region.all.each do |region|
      if params[:regions] && params[:regions].include?(region.id.to_s)
        @campaign.contest_regions.build(:region_id =>  region.id) unless @campaign.region_ids.include?(region.id)
      else
        if contest_region = @campaign.contest_regions.find_by_region_id(region.id)
          @campaign.contest_regions.delete(contest_region)
        end
      end
    end
    contest_types = params[:contest_types]
    contest_types.each_value do |contest_type_params|
      contest_type = @campaign.contest_type(contest_type_params[:contest_type])
      unless contest_type.new_record?
        if contest_type_params[:skin_id].blank?
          @campaign.contest_types.delete(contest_type)
        else
          contest_type.update_attribute(:skin_id, contest_type_params[:skin_id])
        end
      else
        @campaign.contest_types.build(contest_type_params) unless contest_type_params[:skin_id].blank?
      end
    end
    if @campaign.save
      return redirect_to admin_campaigns_path
    end
    render :action => :edit
  end

  def index
    @campaigns = Campaign.all.paginate(:page => params[:page], :per_page => 30)
    @title = "Campaigns"
  end
end
