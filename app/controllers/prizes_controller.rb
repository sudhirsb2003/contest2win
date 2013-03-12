class PrizesController < ApplicationController

  before_filter(:disable, :only => [:redeem])

  before_filter :login_required, :only => [:redeem, :sign_in]

  def prize_points() render :layout => 'home' end

  def view_image
    prize = Prize.find(params[:id])
    render :update do |page|
      page.insert_html :bottom, "body", :partial => 'prize/view_image', :locals => {:prize => prize}
    end  
  end

  def browse_defunct
    params[:winning_date] = 'This Year' unless ['Today','This Week','This Month','This Year'].include? params[:winning_date]
    sql = ''
    conditions = []
    conditions[0] = ""
    if params[:id] && PrizeCategory.exists?(params[:id])
      @category = PrizeCategory.find(params[:id])
      conditions[0] << ' id in (select prize_id from prize_categories_prizes where category_id = ?) and '
      conditions << params[:id]
    else
      params[:id] = nil
    end

    unless params[:contest_type] == 'prize_points'
      conditions[0] << ' id in (select contest_prizes.prize_id from contest_prizes '
      conditions[0] << "inner join contests on contests.id = contest_prizes.contest_id
        and contests.status = #{Contest::STATUS_LIVE} and contests.starts_on <= now()::date and contests.ends_on >= now()::date "
      if params[:contest_type]
        conditions[0] << ' and contests.type = ?'
        conditions << params[:contest_type].classify
      end  
      conditions[0] << " where from_date::date <= now()::date and to_date >= now()::date "
      case params[:winning_date]
      when 'Today'
        conditions[0] << "and to_date::date = now()::date"
      when 'This Week'
        conditions[0] << "and to_date::date <= (now() + interval '1 week')::date"
      when 'This Month'
        conditions[0] << "and to_date::date <= (now() + interval '1 month')::date"
      when 'This Year'
        conditions[0] << "and to_date::date <= (now() + interval '1 year')::date"
      end
      conditions[0] << ')'

    else
      conditions[0] << ' credits > 0 and item_type = \'Object\' '
    end

    unless read_fragment(@prizes_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/10.minutes.to_i}")
      @prizes = Prize.available.paginate(:conditions =>  conditions, :page => params[:page], :per_page => 70)
    end # end read frag

    @title = "#{@category.nil? ? 'All Categories' : @category.name} &raquo; #{params[:winning_date]} &raquo; #{params[:contest_type].nil? ? 'All Channels' : params[:contest_type].humanize}"
  end

  def browse
    sql = ''
    conditions = []
    conditions[0] = ""
    if params[:id] && PrizeCategory.exists?(params[:id])
      @category = PrizeCategory.find(params[:id])
      conditions[0] << ' id in (select prize_id from prize_categories_prizes where category_id = ?) and '
      conditions << params[:id]
    else
      params[:id] = nil
    end
    conditions[0] << ' credits > 0 and item_type = \'Object\' '

    unless read_fragment(@prizes_browse_key = "#{params.to_s.hash}/#{Time.now.to_i/10.minutes.to_i}")
      @prizes = Prize.available.paginate(:conditions =>  conditions, :page => params[:page], :per_page => 70)
    end # end read frag

    @title = @category.present? ? @category.name : 'All Categories'
  end

  def popup
    @prize = Prize.find(params[:id])
    render :layout => false
  end

  def show
    @prize = Prize.find(params[:id])
    @title = "Prizes &raquo; #{@prize.title}"
    @contests = @prize.contests.paginate(:page => params[:page], :per_page => 8)
  end

  def redeem
    @prize = Prize.find(params[:id])
    unless @prize.redeemable_by_user?(current_user)
      unless @prize.redeemable?
        flash[:notice] = 'Sorry, this prize is not redeemable!'
      else  
        if current_user.region_id == @prize.region_id
          flash[:notice] = "Sorry, you don't have enough Prize Points to redeem this prize!"
        else
          flash[:notice] = 'Sorry, this prize is not available in your region.'
        end
      end
      return redirect_to(:action => :show, :id => params[:id])
    end
    if request.post?
      @dispatch = Dispatch.new(params[:dispatch])
      @dispatch.country = current_user.country
      begin
        if  current_user.facebooker? || current_user.reload.password == User.sha1(params[:password])
          Dispatch.transaction do |transaction|
            credit_transaction = current_user.redeem(@prize)
            @dispatch.user_id = current_user.id
            @dispatch.prize_id = @prize.id
            @dispatch.credit_transaction_id = credit_transaction.id
            unless @prize.needs_dd?
              @dispatch.status = Dispatch::STATUSES[:pending_shipment]
              @dispatch.payment_type = 'N/A'
            end  
            @dispatch.save!
          end  
          if @prize.needs_dd?
            flash[:notice] = 'Your prize will be dispatched within 30 working days after we receive your DD.'
          else
            flash[:notice] = 'Your prize will be dispatched within 30 working days.'
          end  
          PrizeMailer.deliver_prize_confirmed_notification(@dispatch, self)
          PrizeMailer.deliver_redemption_notification(@dispatch, self)
          return redirect_to(:action => :browse)
        else #password check failed
          @dispatch.errors.add_to_base 'Password check failed!'
        end  
	    rescue Exception => err
      end
    else
      @dispatch = Dispatch.new(current_user.attributes().delete_if{|k,v| ![:address_line_1, :address_line_2, :city, :state, :country, :pin_code, :mobile_number, :phone_number].include?(k.to_sym)})
    end
  end

  def sign_in
    redirect_to :action => :show, :id => params[:id]
  end
end
