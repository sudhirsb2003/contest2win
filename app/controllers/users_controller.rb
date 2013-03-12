class UsersController < ApplicationController

  before_filter :check_status, :except => [:whoami]
  before_filter :login_required, :only => [:add_friend, :remove_friend, :confirm_acceptance ]
  before_filter(:disable, :only => [:add_friend, :remove_friend, :confirm_acceptance, :reject_prize])

  def profile() end

  def contests_created
    @contests = @user.contests_created.live.find(:all, :offset => params[:offset], :limit => 20)
  end

  def favourite_contests
    @favourites = @user.favourite_contests.online.find(:all, :offset => params[:offset], :limit => 20)
  end

  def contests_played
    @responses = @user.responses.online.latest.find(:all, :offset => params[:offset], :limit => 20)
  end

  def add_friend
    unless current_user.friends.exists?(@user)
      current_user.friends << @user
      UserMailer.deliver_friend_request_notification(self, current_user, @user)
      flash[:notice] = "#{@user.username} has been added to your list of friends."
    else
      flash[:notice] = "#{@user.username} was already present in your list of friends."
    end  
    redirect_to user_url(:username => @user.username)
  end

  def remove_friend
    if friendship = current_user.friendships.find_by_friend_id(@user)
      friendship.destroy
    end  
    respond_to do |format|
      format.html {redirect_to user_url(:username => current_user.username, :action => :friends)}
      format.js {render :nothing => true}
    end
  end

  def referrals
    @referrals = @user.referrals.find(:all, :offset => params[:offset], :limit => 30)
  end

  def friends
    @friends = @user.friends.find(:all, :offset => params[:offset], :limit => 30)
  end

  def prize_points
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user) || logged_in?(:admin)
    @transactions = @user.credit_transactions.paginate(:all, :page => params[:page], :per_page => 30, :order => 'created_on desc')
  end

  def unapproved_contests
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user) || logged_in?(:admin)
    @contests = @user.contests_created.pending_or_drafts.paginate(:conditions => ['user_id = ?', current_user.id], :page => params[:page], :per_page => 20)
  end

  def unapproved_questions
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user) || logged_in?(:admin)
    @questions = @user.questions.pending_or_drafts.paginate(:page => params[:page], :per_page => 20)
  end

  # Confirms that the user accepts a prize.
  # The link to this action is embedded into the email sent
  # to users who have been short listed for a prize. 
  def confirm_acceptance
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user)
    @short_listed_winner = current_user.short_listed_winnings.find(params[:id])
    if @short_listed_winner.pending?
      if request.get?
        @dispatch = Dispatch.new(current_user.attributes().delete_if{|k,v| ![:address_line_1, :address_line_2, :city, :state, :country, :pin_code, :mobile_number, :phone_number].include?(k.to_sym)})
        @dispatch.prize = @short_listed_winner.prize
      else
        begin
          Dispatch.transaction do |transaction|
            @dispatch = Dispatch.new(params[:dispatch])
            @dispatch.user_id = current_user.id
            @dispatch.country = current_user.country
            @dispatch.prize_id = @short_listed_winner.prize.id
            @dispatch.short_listed_winner_id = params[:id]
            if !@dispatch.prize.needs_dd?
              @dispatch.status = Dispatch::STATUSES[:pending_shipment]
              @dispatch.payment_type = 'N/A'
            end  
            @dispatch.save!

            @short_listed_winner.accepted = true
            @short_listed_winner.confirmed_on = Time.now
            @short_listed_winner.save!
  
            if @dispatch.prize.needs_dd?
              flash[:notice] = 'Your prize will be dispatched within 30 working days after we receive your DD.'
            else
              flash[:notice] = 'Your prize will be dispatched within 30 working days.'
            end  
            PrizeMailer.deliver_prize_confirmed_notification(@dispatch, self)
            return redirect_to(:action => :pending_prizes)
          end
	    rescue Exception => err
          #logger.error(err.to_s)
        end #begin
      end #get?
    else
      case @short_listed_winner.status
      when 'Accepted' then flash.now[:notice] = 'You have already accepted this prize.'
      when 'Rejected' then flash.now[:notice] = 'You have rejected this prize.'
      when 'Expired' then flash.now[:notice] = 'Oops! Looks like you’re a little late. The confirmation period for your prize claim has expired. But you can still play more contests to WIN more amazing prizes.'
      end
    end # pending?
    render :layout => 'users'
  end

  def reject_prize
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user)
    short_listed_winner = current_user.short_listed_winnings.find(params[:id])
    unless short_listed_winner.confirmed?
      short_listed_winner.accepted = false
      short_listed_winner.confirmed_on = Time.now
      short_listed_winner.save
      flash[:notice] = 'Prize rejected!'
    end
    redirect_to :action => :pending_prizes
  end

  def pending_prizes
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user) || logged_in?(:admin)
    @short_listed_winners = current_user.short_listed_winnings.pending(:all)
  end

  def send_referral_mail
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless current_user?(@user)
    @referral_mail = Email::Referral.new(params[:referral_mail].merge(:from_user_id => @user.id))
    render :update do |page|
      if @referral_mail.valid?
        GenericMailer.deliver_referral_mail(@referral_mail, url_for(account_url(:action => :register, :referred_by => @user.username)))
        page[:referral_mail_form].hide();
        @referral_mail = nil
        page.replace_html :referral_mail_form, :partial => 'referral_mail_form'
        page[:referral_mail_sent].show();
      else
        page.replace_html :referral_mail_form, :partial => 'referral_mail_form'
      end
    end
  end

  # Gets the currently logged in user's info. If no user is logged-in, returns a status code of 401 (access denied) 
  def whoami
    if logged_in?
      render :xml => current_user.to_xml(:base_url => request.host_with_port)
    else
      render :nothing => true, :status => 401
    end  
  end

  private
  def check_status
    if @user = User.find_by_username(params[:username])
      return render(:action => :account_disabled, :layout => 'application') unless @user.live? || logged_in?(:admin)
    else
      return render(:template => 'shared/access_denied', :status => :unauthorized, :layout => 'application')
    end  
  end
end
