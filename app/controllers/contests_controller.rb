class ContestsController < ApplicationController
  TIME_PARAMS = ['This Week', 'This Month', 'All Time']

  #before_filter :login_required, :only => [:vote, :add_comment, :delete_comment, :toggle_favourite, :sign_in]
  before_filter :check_deactivated
  before_filter :before_save, :only => [:new, :edit]

  before_filter(:disable,
      :only => [:new, :edit, :delete, :finished_creating, :add_comment, :delete_comment, :toggle_favourite, :vote,
        :edit_question, :add_question, :confirm_question, :add_option, :add_entry, :edit_entry, :confirm_entry, :delete_entry, :add_questions, :confirm ])

  cache_sweeper :contests_sweeper, :only => [ :edit, :delete_entry ]
  #caches_page :related, :by_user, :recent_players, :top_players, :details, :contests_with_prizes

  def redirect_to_play
    redirect_to contest_path(Contest.find(params[:id]).url_attributes) rescue redirect_to('/404')
  end

  def finished
    @contest_response = get_my_latest_response(@contest.id)
    return redirect_to(contest_url(@contest.url_attributes(:action => :play))) unless @contest_response
    render :layout => 'contest', :template => 'contests/finished'
  end
  def index
    redirect_to contests_path(:action => :most_recent)
  end

  def finished_creating
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless @contest.editable?(current_user)
    @contest.finished_creating
    return redirect_to(contest_url(@contest.url_attributes(:action => :questions)))
  end

  def sign_in
    redirect_to @contest.url_attributes(:action => :play)
  end

  def vote
    @contest.toggle_vote(current_user.id)
    @contest.reload
    respond_to do |format|
      format.html { redirect_to @contest.url_attributes(:action => :play) }
      format.js { render :partial => 'votes'}
    end
  end

#  def change_response_view_level
#    @contest_response = Response.find(params[:response_id])
#    if @contest_response.user == current_user
#      @contest_response.update_attribute(:view_level, params[:contest_response][:view_level])
#    end
#    render :nothing => true
#  end

  def add_comment
    unless request.xhr?
      return redirect_to(contest_url(@contest.url_attributes))
    end

    @contest = Contest.find(params[:id])
    @comment = @contest.comments.build(params[:comment])
    @comment.sticky = false unless logged_in?(:admin)
    @comment.user = current_user
    @comment.status = Comment::STATUS_APPROVAL_PENDING

    if @comment.save
      flash.now[:comment_notice] = 'Thank you for your comment. It\'ll be available online right after we review it.'
      #render :text => 'Thank you for your comment. It\'ll be available online right after we review it.'
      @comment = Comment.new
    end
    render :partial => 'contests/comment_form';
  end

  def delete
    if @contest.deletable?(current_user)
      if @contest.live?
        @contest.soft_delete(current_user)
      else
        @contest.destroy
      end  
      render :nothing => true
    else
      render :update do |page|
        page.alert("You don't have permissions to do that!")
      end  
    end  
  end

  def delete_comment
    comment = @contest.all_comments.find(params[:comment_id])
    if comment.deleteable?(current_user)  
      comment.destroy
      render :nothing => true
    end  
  end

  # Renders the partial <tt>related_list</tt> with contests that
  # belong to the user (params[:id])
  def by_user
    contests = @contest.user.contests_created.live.running.find(:all, :limit => 5, :order => 'random()', :conditions => "contests.id != #{@contest.id}")
    render :update do |page|
      page.replace_html "more_from_user_body", :partial => 'contests/contests_panel_body', :locals => {:contests => contests}
    end
  end

  # Renders the partial <tt>related_list</tt> with contests that
  # have matching tags.
  def related
    begin
      @contests = @contest.related(5)
    rescue
      flash.now[:error] = "Oops! We seem to be having a problem fetching the related contests."
      @contests = []
    end
    respond_to do |format|
      #format.html {render :partial => 'contests/contests_panel'}
      format.js {render :partial => 'contests/contests_panel'}
      format.xml { render :xml => @contests.to_xml(:base_url => request.host_with_port, :root => 'contests') }
    end
  end

  def contest_response
    if params[:response_id]
      @contest_response = @contest.responses.find(params[:response_id], :include => :contest)
    else  
      @contest_response = get_my_latest_response(@contest.id, false)
      @contest_response = @contest.responses.build if @contest_response.nil?
    end  
    respond_to do |format|
      format.html {render :layout => 'contest'}
      format.xml { return render(:xml => @contest_response.to_xml(:base_url => request.host_with_port)) }
    end
  end

  # Sending contests to a friend.
  def share
    @title = "Share #{@contest.title}"
    @contest = Contest.find(params[:id])
    if request.get?
      @recommendation = ContestRecommendation.new(:message => "This is fun stuff!")
      if logged_in?
        @recommendation.from_email_address = current_user.email
        @recommendation.from_name = current_user.full_name
      end  
    else
      @recommendation = ContestRecommendation.new(params[:recommendation])
      @recommendation.contest_id = @contest.id
      if @recommendation.save
        # send email...
        ContestMailer.deliver_recommendation(@recommendation, self)
        flash.now[:notice] = "Mail sent!"
        @mail_sent = true
      end
    end  
    render :template => 'contests/share', :layout => 'popup'
  end

  def send_recommendation
      @contest = Contest.find(params[:id])
      @recommendation = ContestRecommendation.new(params[:recommendation])
      @recommendation.contest_id = @contest.id
      ContestRecommendation.transaction do 
      if @recommendation.save
        # send email...
        ContestMailer.deliver_recommendation(@recommendation, self)
        render :update do |page|
          page.remove('popup_container')
        end
      else
        render :update do |page|
          page.replace 'popup_container',  :partial => 'contests/recommend'
        end
      end  
      end # transaction
  end

  def top_players
    responses = @contest.responses.top_scores.find(:all, :limit => 5)
    render :update do |page|
      page.replace_html "top_players_body", :partial => 'contests/responses_panel_body', :locals => {:responses => responses}
    end
  end

  def most_played
    @time = TIME_PARAMS.include?(params[:time]) ? params[:time] : 'This Month'
    conditions = build_conditions
    klass = eval "#{params[:controller].classify}.new.class"
    unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
      @contests = klass.live.running.most_played.paginate(:all, :conditions => conditions, :page => params[:page], :per_page => 20)
    end
    browse
  end


  def top_rated
    @time = TIME_PARAMS.include?(params[:time]) ? params[:time] : 'This Month'
    conditions = build_conditions
    unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
      klass = eval "#{params[:controller].classify}.new.class"
      @contests = klass.live.running.top_rated.paginate(:all, :conditions => conditions, :page => params[:page], :per_page => 20)
    end
    browse
  end

  def most_recent
    @time = 'All Time'
    conditions = build_conditions
    unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
      klass = eval "#{params[:controller].classify}.new.class"
      @contests = klass.live.running.recent.paginate(:all, :conditions => conditions, :page => params[:page], :per_page => 20)
    end
    browse
  end

  def featured
    @time = TIME_PARAMS.include?(params[:time]) ? params[:time] : 'This Month'
    conditions = build_conditions
    unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
      klass = eval "#{params[:controller].classify}.new.class"
      @contests = klass.live.running.featured.paginate(:all, :conditions => conditions, :page => params[:page], :per_page => 20)
    end
    browse
  end

  def prize_points
    @time = 'All Time'
    conditions = build_conditions
    unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
      klass = eval "#{params[:controller].classify}.new.class"
      @contests = klass.live.running.with_prize_points.paginate(:all, :conditions => conditions, :page => params[:page], :per_page => 20)
    end
    browse
  end

  # Action for 404 page 
  def contests_with_prizes_404
    @contests = Contest.live.running.featured.find(:all, :limit => 9)
    render :layout => 'minimal'
  end

  def prizes
    @time = TIME_PARAMS.include?(params[:time]) ? params[:time] : 'All Time'
    conditions = build_conditions('contest_prizes.from_date <= now() and contest_prizes.to_date >= now()::date')
    unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
      klass = eval "#{params[:controller].classify}.new.class"
      @contests = klass.live.running.with_prizes.paginate(:conditions => conditions, :count => {:select => 'distinct contests.id'}, :page => params[:page], :per_page => 20)
    end
    browse
  end

  def tags
    @time = TIME_PARAMS.include?(params[:time]) ? params[:time] : 'All Time'
    klass = eval "#{params[:controller].classify}.new.class"
    conditions = build_conditions
    if @tag = params[:tag]
      unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
        conditions = {}
        conditions[:categories] = @category.name if @category
        if @time == 'This Week'
          conditions[:this_week] = 't'
        elsif @time == 'This Month'
          conditions[:this_month] = 't'
        end
        @contests = klass.find_by_tag2(@tag, conditions, params[:page], 20)
      end
      return browse
    else
      unless read_fragment(@contest_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/1.hour.to_i}")
        @tags = klass.tags({:conditions => conditions})
      end
      render :template => 'contests/tags', :layout => 'browse'
    end
  end

  def toggle_favourite
    @contest.toggle_favourite(current_user.id)
    @contest.reload
    respond_to do |format|
      format.html {redirect_to contest_url(@contest.url_attributes)}
      format.js {render :partial => 'contests/favourite', :locals => {:contest => @contest}}
    end  
  end

  def details
    if @contest.live?
      render :xml => @contest.to_xml(:base_url => request.host_with_port, :current_user => current_user)
    else
      render :nothing => true, :status => :forbidden
    end  
  end

  def winners
    @winners = @contest.winners.paginate(:page => params[:page], :per_page => 10)
    render :template => 'contests/winners', :layout => 'contest'
  end

  def report_copyright_violation
    @contest = Contest.find(params[:id])
    @copyright_violation = CopyrightViolation.new(params[:copyright_violation])
    unless params[:copyright_violation]      
      if logged_in?
        @copyright_violation.from_email_address = current_user.email
        @copyright_violation.from_name = current_user.full_name
        @copyright_violation.contact = current_user.mobile_number
      end  
    else
      if @copyright_violation.valid?
        @copyright_violation.contest_id = @contest.id
        ContestMailer.deliver_copyright_violation(@copyright_violation,self)
        render :update do |page|
          page.alert('Email Sent!')
          page.hide("send_copyright_violation_via_email");
          page.replace_html 'send_copyright_violation_via_email', ''
        end
      return
      end      
    end
    render :update do |page|
      page.replace_html 'send_copyright_violation_via_email', :partial => 'contests/report_copyright_violation'
    end		
  end

  def post_to_facebook
    if (contest_response = Response.find(params[:response_id])) && (contest_response.recently_completed?)
      contest = contest_response.contest
      image_src = nil
      if RAILS_ENV == "development"
        image_src = "http://static.c2w.com/uploads/question/image/81/43/99/N814399/thumb/file.jpg"
      else
        image_src = contest.default_image
      end
      contest_url = contest_url(contest.url_attributes(:s => :fb))
      args = {
        :method => 'feed',
        :name => contest.title,
        :caption => contest.response_caption,
        :description => contest.description,
        :link => contest_url,
        :picture => image_src,
        :actions => { :name => 'Play', :link => contest_url },
        :user_message_prompt => 'Share your result with your friends'
      }
      respond_to do |f|
        f.json {
      render :update do |page|
        page.call 'postToFB', args.to_json
      end
      return
        }
      end
    end
    render :nothing => true
  end

  private

  def browse
    @title = "#{params[:action].humanize} #{params[:controller].humanize}"
    @title = "#{@category.name}: #{@title}" if @category
    @title = "#{@title}: #{@campaign.title}" if @campaign
    respond_to do |format|
      format.html {
          @rss_link = url_for(:format => 'rss', :page=> nil)
          render :layout => 'browse', :template => 'contests/browse'
        }
      format.xml { render :xml => @contests.to_xml(:only => [:title, :id], :brief => true, :base_url => request.host_with_port, :root => 'contests') }
      format.json { render :json => @contests.to_json(:base_url => request.host_with_port)}
      #format.json { render :json => @contests.to_a.to_json(:base_url => request.host_with_port)}
      format.rss { render :layout => false, :template => 'contests/rss.rxml' }
    end  
  end


  def get_my_latest_response(contest_id, create_new = false)
    if logged_in?
      my_response = Response.latest_by_contest_id_and_user_id(contest_id, current_user.id)
    elsif session[:uuid]
      my_response = Response.latest_by_contest_id_and_session_id(contest_id, session[:uuid])
    end
	if create_new && my_response.nil?
		if logged_in?
			my_response = @contest.responses.create({:user_id => current_user.id})
		else
			my_response = @contest.responses.create({:session_id => session_uuid})
		end
	end		
    my_response
  end

  def before_validation
    self.content_type = 'All' if content_type.empty?
  end

  def check_deactivated
    if params[:id]
      begin
        if ['play','questions','entries','finished','winners','details'].include? params[:action]
          @contest = Contest.find(params[:id], :include => [:skin, :categories, :tags])
        else
          @contest = Contest.find(params[:id])
        end  
      rescue ActiveRecord::RecordNotFound
        #return render(:template => '../../public/404'), :status => 404
        return redirect_to('/404')
      end
      unless @contest.available? || logged_in?(:moderator) || ((@contest.approval_pending? || @contest.draft?) && current_user?(@contest.user))
        return render(:template => 'contests/not_available')
      end
    end
  end

  def build_conditions(initial_condition = ' 1=1 ')
    conditions = []
    conditions[0] = initial_condition
    case @time
      when 'This Month' then conditions[0] << " and starts_on >= now()::date - interval '1 month' "
      when 'All Time' then true
      else
        conditions[0] << " and starts_on >= now()::date - interval '7 days' "
    end
    if params[:campaign_id] && (@campaign = Campaign.find(params[:campaign_id]) rescue nil)
      conditions[0] << " and campaign_id = #{@campaign.id} "
    else
      params[:campaign] = nil
    end
    if params[:search] && !params[:search].blank?
      @search = params[:search]
      conditions[0] << " and contests.title = ?"
      conditions << @search
    end
    if params[:catid] && (@category = Category.find_by_id(params[:catid])).present?
      @catid = params[:catid]
      conditions[0] << " and contests.id = (select contest_id from categories_contests where categories_contests.category_id = ? and categories_contests.contest_id = contests.id limit 1) "
      conditions << @category.id
    else
      params[:catid] = nil
    end
    
    conditions
  end

  def check_editable 
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless @contest.editable?(current_user)
  end 

  def before_save 
    if request.post? && ! logged_in?(:admin)
      banned = %w(starts_on ends_on) # we don't want non-admins to set these
      params[:contest].delete_if { |k,v| banned.include?(k.gsub(/\(.*\)/,'')) } # we remove starts_on(1i) type of params
    end  
  end

end
