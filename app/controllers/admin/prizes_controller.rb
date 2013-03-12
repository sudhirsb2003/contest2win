class Admin::PrizesController < AdminController
  layout 'admin'

  def list
    @prizes = Prize.paginate(:order => :title, :page => params[:page], :per_page => 10)
  end

  def new
    if request.post?
      @prize = Prize.new(params[:prize])
      if @prize.save
        flash[:notice] = 'Prize Created!'
        redirect_to :action => :edit, :id => @prize.id
      end  
    else
      @prize = Prize.new  
    end
  end

  def edit
    @prize = Prize.find(params[:id])
    if request.post?
      params[:prize].delete(:region_id) unless @prize.region_editable?
      if @prize.update_attributes(params[:prize])
        flash[:notice] = 'Prize Updated!'
        expire_page :controller => '/prizes', :action => :popup, :id => @prize.id
      end  
    end
  end

  # Lists contests that have prizes
  def contests
    @contests = Contest.with_prizes.paginate(:total_entries => Contest.with_prizes.count('distinct contests.id'), :page => params[:page], :per_page => 10)
  end

  def contest
    @contest = Contest.find(params[:id])
    @prizes = @contest.contest_prizes.find(:all)
  end

  #def add_contest_prize
    #@contest_prize = ContestPrize.new
    #render :partial => 'contest_prize_form'
  #end

  def add_contest_prize
    @contest = Contest.find(params[:id])
    @contest_prize = @contest.contest_prizes.build(params[:contest_prize])
    if params[:contest_prize]
      @contest_prize.created_by_id = current_user.id
      if @contest_prize.save
        ContestMailer.deliver_contest_prize_added_notification(@contest_prize, self)
        render :action => 'add_contest_prize.rjs' and return
      end
    end
    render :partial => 'add_contest_prize', :status => (@contest_prize.errors.empty? ? :success : :failure)
  end

  def edit_contest_prize
    @contest_prize = ContestPrize.find(params[:id])
    @contest = @contest_prize.contest
    if params[:contest_prize]
      @contest_prize.attributes = params[:contest_prize]
      if @contest_prize.save
        render :partial => 'contest_prize' and return
      end  
    end
    render :partial => 'edit_contest_prize'
  end

  def contest_prize
    @contest_prize = ContestPrize.find(params[:id])
    render :partial => 'contest_prize' and return
  end

  def contest_prize_cancel
    @contest = Contest.find(params[:id])
    render :partial => 'add_contest_prize_link'
  end

  def delete_contest_prize
    contest_prize = ContestPrize.find(params[:id])
    if contest_prize.deletable?
      expire_page :controller => '/prizes', :action => :popup, :id => contest_prize.prize.id
      ContestPrize.delete(params[:id])
    end
    render :nothing => true
  end

  def top_scorers
    @contest_prize = ContestPrize.find(params[:id])
    @contest = @contest_prize.contest
    @top_scorers = @contest_prize.top_scorers({:order => params[:order]}).to_a
  end

  # manually short list an individual user without regard to the score
  def short_list_user
    if request.post?
      contest_prize = ContestPrize.find(params[:id])
      begin
        raise 'No more prizes left to be declared' if contest_prize.count_prizes_left <= 0
        if user = User.find_by_username(params[:username])
          unless params[:force] == 'true'
            if short_listed_winnings = contest_prize.contest.find_winnings_by_user_id(user.id)
              render :update do |p|
                p.replace_html "error_msg", "User has been short listed #{short_listed_winnings.size} times before for this contest!"
                p.replace_html "previous_winnings", :partial => 'previous_winnings', :locals => {:short_listed_winnings => short_listed_winnings}
                p.show('previous_winnings')
                p.show('force_option')
                p.call 'done'
              end
              return
            end
          end
          winner = contest_prize.short_listed_winners.create(:user_id => user.id)
          winner.log(AuditLog::SHORT_LISTED, current_user)
          if contest_prize.prize.prize_points?
            winner.accepted = true
            winner.confirmed_on = Time.now
            ShortListedWinner.transaction do
              winner.save!
              winner.user.credit_transactions.create!(:amount => contest_prize.prize.credits,
                :description => "For winning contest - #{contest_prize.contest.title}")
            end
            PrizeMailer.deliver_winner_notification(winner, self)
          else
            if contest_prize.region.india?
              if contest_prize.prize.needs_dd?
                PrizeMailer.deliver_winner_short_listed_notification_with_tds(winner, self)
              else
                PrizeMailer.deliver_winner_short_listed_notification_no_tds(winner, self)
              end
              if winner.user.mobile_number && winner.user.mobile_number.strip != ""
                SmsAlert.create(:user_id => winner.user_id, :msisdn => winner.user.mobile_number)
             end  
            else
              if contest_prize.prize.cash?
                PrizeMailer.deliver_winner_short_listed_notification_to_us_user_for_cash_prize(winner, self)
              else
                PrizeMailer.deliver_winner_short_listed_notification_to_us_user_for_non_cash_prize(winner, self)
              end
            end  
          end  
        else
          raise 'User not found!'
        end
        flash[:notice] = 'Winner short listed and notified'
        render :update do |p|
          p.redirect_to prizes_management_url(:id => params[:id], :action => :short_listed)
        end
      rescue
        render :update do |p|
          p.replace_html "error_msg", $!
          p.call 'done'
        end
      end
    end
  end

  def short_list_winners
    return redirect_to(prizes_management_url(:action => :top_scorers, :id => params[:id])) unless request.post?
    unless params[:ids]
      flash[:notice] = 'No users were selected!'
      return redirect_to(prizes_management_url(:action => :top_scorers, :id => params[:id]))
    end
    contest_prize = ContestPrize.find(params[:id])
    unless contest_prize.ended?
      flash[:notice] = 'This prize is not yet due to be declared!'
      return redirect_to(prizes_management_url(:action => :top_scorers, :id => params[:id]))
    end
    params[:ids].each_value do |id|
      entry, user_id = nil,nil
      contest = contest_prize.contest
      entry = nil
      user_id = id
      break if contest_prize.count_prizes_left <= 0
      unless contest_prize.short_listed_winners.find_by_user_id(user_id)
        #winner = contest_prize.short_listed_winners.create(:user_id => user_id, :contest_prize_id => contest_prize.id)
        winner = contest_prize.short_listed_winners.create(:user_id => user_id, :entry => entry)
        winner.log(AuditLog::SHORT_LISTED, current_user)
        if contest_prize.prize.prize_points?
          winner.accepted = true
          winner.confirmed_on = Time.now
          ShortListedWinner.transaction do
            winner.save!
            winner.user.credit_transactions.create!(:amount => contest_prize.prize.credits,
              :description => "For winning contest - #{contest_prize.contest.title}")
          end
          PrizeMailer.deliver_winner_notification(winner, self)
        else
          if contest_prize.region.india?
            if contest_prize.prize.needs_dd?
              PrizeMailer.deliver_winner_short_listed_notification_with_tds(winner, self)
            else
              PrizeMailer.deliver_winner_short_listed_notification_no_tds(winner, self)
            end
            if winner.user.mobile_number && winner.user.mobile_number.strip != ""
              SmsAlert.create(:user_id => winner.user_id, :msisdn => winner.user.mobile_number)
            end  
          else
            if contest_prize.prize.cash?
              PrizeMailer.deliver_winner_short_listed_notification_to_us_user_for_cash_prize(winner, self)
            else
              PrizeMailer.deliver_winner_short_listed_notification_to_us_user_for_non_cash_prize(winner, self)
            end
          end
        end  
      end
    end
    redirect_to prizes_management_url(:action => :short_listed, :id => contest_prize.id)
  end

  def short_listed
    @contest_prize = ContestPrize.find(params[:id])
    @contest = @contest_prize.contest
    @short_listed_winners = @contest_prize.short_listed_winners
  end

  # Displays contests for which winners can be picked. 
  def pick_winners
    conditions = params[:region_id].blank? ? nil : ['region_id = ?', params[:region_id]]
    @contest_prizes = ContestPrize.declarable.paginate(:conditions => conditions, :page => params[:page], :per_page => 30)
  end

  def close_prize
    ContestPrize.find(params[:id]).update_attribute(:status, ContestPrize::STATUS_CLOSED)
    render :nothing => true
  end

  def open_prize
    ContestPrize.find(params[:id]).update_attribute(:status, ContestPrize::STATUS_OPEN)
    render :nothing => true
  end

  def dispatches
    if params[:dispatch_search] || session[:dispatch_search]
      if params[:dispatch_search]
        @dispatch_search = DispatchSearch.new params[:dispatch_search]
        session[:dispatch_search] = @dispatch_search
      else
        @dispatch_search = session[:dispatch_search]
      end      
      conditions = ['1=1']
      includes = ['user', 'prize']
      unless @dispatch_search.search_term.empty?
        search_term = @dispatch_search.search_term
        if 'username' == @dispatch_search.search_by
          conditions[0] << ' and users.username = ?'
        elsif 'email' == @dispatch_search.search_by
          conditions[0] << ' and users.email = ?'
        elsif 'dispatch_id' == @dispatch_search.search_by
          conditions[0] << ' and dispatches.id = ?'
        end
        conditions << search_term
      end
      unless @dispatch_search.dispatch_status.blank?
        conditions[0] << ' and dispatches.status = ? '
        conditions << @dispatch_search.dispatch_status
      end
      unless @dispatch_search.region_id.blank?
        conditions[0] << ' and prizes.region_id = ? '
        conditions << @dispatch_search.region_id
      end      
      @dispatches = Dispatch.paginate(:conditions => conditions, :include => includes, :page => params[:page], :per_page => 30)      
    end      
  end

  def cancel_dispatch
    @dispatch = Dispatch.find(params[:id])
    if @dispatch.status == Dispatch::STATUSES[:shipped]
      @dispatch.errors.add_to_base('This dispatch has already been shipped.')
    elsif @dispatch.status == Dispatch::STATUSES[:canceled]
      @dispatch.errors.add_to_base('This dispatch was already canceled.')
    else
      @dispatch.update_attributes(params[:dispatch])
      @dispatch.status = Dispatch::STATUSES[:canceled]
      @dispatch.actioned_by_id = current_user.id
      @dispatch.actioned_on = Time.now
      if @dispatch.save
        render :update do |page| page.redirect_to :action => :dispatch, :id => @dispatch.id end
        return
      end  
    end
    render :partial => 'cancel_dispatch_form', :status => :error
  end

  def dispatch
    @dispatch = Dispatch.find(params[:id])
  end

  def update_dispatch_payment_details
    @dispatch = Dispatch.find(params[:id])
    @dispatch.update_attributes(params[:dispatch])
    @dispatch.status = Dispatch::STATUSES[:pending_shipment]
    if @dispatch.save
      render :update do |page| page.redirect_to :action => :dispatch, :id => @dispatch.id end
      return
    end
    render :partial => 'payment_details_form', :status => :error
  end

  def update_dispatch_details
    @dispatch = Dispatch.find(params[:id])
    @dispatch.update_attributes(params[:dispatch])
    @dispatch.status = Dispatch::STATUSES[:shipped]
    @dispatch.actioned_by_id = current_user.id
    if @dispatch.save
      render :update do |page| page.redirect_to :action => :dispatch, :id => @dispatch.id end
      return
    end  
    render :partial => 'dispatch_details_form', :status => :error
  end

  def region_changed
    prizes = Prize.all.find_all_by_region_id(params[:region_id].to_i)
    render :partial => 'contest_prize_form_prizes.html.erb', :locals => {:prizes => prizes, :prize_id => 0}
  end

  protected
  def authorize?(user)
     user && user.crm?
  end

  private
  def stream_csv
     filename = params[:action] + ".csv"    
  
     #this is required if you want this to work with IE        
     if request.env['HTTP_USER_AGENT'] =~ /msie/i
       headers['Pragma'] = 'public'
       headers["Content-type"] = "text/plain" 
       headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
       headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" 
       headers['Expires'] = "0" 
     else
       headers["Content-Type"] ||= 'text/csv'
       headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
     end
  
    render :text => Proc.new { |response, output|
      csv = FasterCSV.new(output, :row_sep => "\r\n") 
      yield csv
    }
  end
end
