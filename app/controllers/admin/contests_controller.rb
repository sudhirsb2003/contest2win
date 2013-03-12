class Admin::ContestsController < AdminController
  layout 'admin'
  cache_sweeper :contests_sweeper, :only => [ :approve_entry, :approve_question,
      :activate_contest, :deactivate_contest, :manage_questions, :manage_contests, :manage_comments, :manage_entries ]

  def entries
    @title = 'Entries Pending Approval'
    @entries = Entry.pending.paginate(:page => params[:page], :per_page => 30)
  end

  def manage_entries  
    if params[:entry_ids]
      params[:entry_ids].each_value do |id|
        if Entry.exists?(id)
          entry = Entry.find(id)
          if 'Delete' == params[:commit]
            entry.soft_delete(current_user)
          else
            entry.approve(current_user)
          end
        end
      end
    end
    redirect_to :action => :entries
  end

  def questions
    @title = 'Questions Pending Approval'
    @questions = Question.pending.paginate(:page => params[:page], :per_page => 30)
  end

  def manage_questions
    if params[:question_ids]
      params[:question_ids].each_value do |id|
        if Question.exists?(id)
          question = Question.find(id)
          if 'Delete' == params[:commit]
            question.soft_delete(current_user)
          else
            question.approve(current_user)
          end  
        end
      end
    end
    redirect_to :action => :questions
  end

  def approve_entry
    Entry.find(params[:id]).approve(current_user) if Entry.exists?(params[:id])
    render :nothing => true
  end

  def approve_question
    Question.find(params[:id]).approve(current_user) if Question.exists?(params[:id])
    render :nothing => true
  end

  def contests
    @title = 'Contests Pending Approval'
    @contests = Contest.pending.paginate(:page => params[:page], :per_page => 30)
  end

  def manage_contests
    if params[:contest_ids]
      params[:contest_ids].each_value do |id|
        if Contest.exists?(id)
          contest = Contest.find(id)
          if 'Delete' == params[:commit]
            contest.soft_delete(current_user)
            ContestMailer.deliver_contest_rejected_notification(contest, self)
          else
            contest.approve(current_user)
            ContestMailer.deliver_contest_added_notification(contest, self)
          end
        end
      end
    end
    redirect_to :action => :contests
  end

  def comments
    @title = 'Pending Comments'
    @comments = Comment.pending.paginate(:page => params[:page], :per_page => 30)
  end

  def manage_comments
    if params[:comment_ids]
      params[:comment_ids].each_value do |id|
        if Comment.exists?(id)
          comment = Comment.find(id)
          if 'Delete' == params[:commit]
            comment.soft_delete(current_user)
          else
            comment.approve(current_user)
            ContestMailer.deliver_comment_added_notification(comment, self) if comment.user.id != comment.contest.user.id \
                  && !comment.contest.user.has_preference?(UserPreference::PREFERENCE_TYPES[:no_mail_on_comment])
          end
        end
      end
    end
    redirect_to :action => :comments
  end


  def approve_comment
    if Comment.exists?(params[:id])
      @comment = Comment.find(params[:id])
      @comment.approve(current_user)
      ContestMailer.deliver_comment_added_notification(@comment, self) unless @comment.user.id == @comment.contest.user.id
    end
    render :nothing => true
  end

  def deactivated_contests
    @title = 'Deactivated Contests'
    @contests = Contest.deactivated.paginate(:page => params[:page], :per_page => 30)
  end

  def expired_contests
    @title = 'Expired Contests'
    @contests = Contest.expired.live.paginate(:page => params[:page], :per_page => 30)
  end

  def disabled_user_accounts
    @title = 'Disabled user accounts'
    @users = User.find(:all, :conditions => "users.status = #{User::STATUS_DISABLED}", :order => 'users.id', :page => {:current => params[:page]})
  end

  def disable_user_account
    if User.exists?(params[:id])
      user = User.find(params[:id])
      if current_user?(user)
        flash[:notice] = 'You cannot disable your own account!'
      else
        flash[:notice] = 'This user\'s account is now disabled!'
        user.update_attribute(:status, User::STATUS_DISABLED)
      end  
      return redirect_to(user_url(:username => user.username))
    end
    redirect_to :back
  end

  def enable_user_account
    if User.exists?(params[:id])
      user = User.find(params[:id])
      flash[:notice] = 'This user\'s account is now enabled!'
      user.update_attribute(:status, User::STATUS_LIVE)
      return redirect_to(user_url(:username => user.username))
    end
    redirect_to :back
  end

  def change_users_level
  end

  def deactivate_contest
    @contest = Contest.find(params[:id])
    @contest.deactivate(current_user)
    redirect_to contest_url(@contest.url_attributes)
  end

  def activate_contest
    @contest = Contest.find(params[:id])
    @contest.activate(current_user)
    flash.now[:notice] = 'This contest has been activated.'
    redirect_to contest_url(@contest.url_attributes)
  end

  def toggle_login_required
    if logged_in?(:admin)
      Contest.transaction do
        contest = Contest.find(params[:id])
        contest.toggle!(:login_required)
        contest.log(contest.login_required? ? AuditLog::LOGIN_REQUIRED_ENABLED : AuditLog::LOGIN_REQUIRED_DISABLED, current_user) 
      end
    end  
    render :nothing => true
  end

  def toggle_locked_contest
    if logged_in?(:admin)
      Contest.transaction do
        contest = Contest.find(params[:id])
        contest.toggle(:locked).save
        contest.log(contest.locked? ? AuditLog::LOCKED : AuditLog::UNLOCKED, current_user) 
      end
    end  
    render :nothing => true
  end

  def toggle_loyalty_points_enabled
    if logged_in?(:admin)
      Contest.transaction do
        contest = Contest.find(params[:id])
        contest.toggle(:loyalty_points_enabled).save
        contest.log(contest.loyalty_points_enabled? ? AuditLog::LOYALTY_ENABLED : AuditLog::LOYALTY_DISABLED, current_user) 
      end
    end  
    render :nothing => true
  end

  def toggle_featured_contest
    if logged_in?(:admin)
      Contest.transaction do
        contest = Contest.find(params[:id])
        contest.toggle(:featured).save
        contest.log(contest.featured? ? AuditLog::FEATURED : AuditLog::UNFEATURED, current_user) 
        ContestMailer.deliver_contest_featured_notification(contest, self) if contest.featured?
      end
    end  
    render :nothing => true
  end

  def remap_categories
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless logged_in?(:super_admin)
    if request.post? && (src = Category.find(params[:src].to_i) rescue nil) && (dest = Category.find(params[:dest].to_i) rescue nil)
      if src.id != dest.id
        count = src.contests.count
        Contest.connection.execute("update categories_contests set category_id = #{dest.id} where category_id = #{src.id} and categories_contests.contest_id not in (select contest_id from categories_contests where category_id = #{dest.id})")
        Contest.connection.execute("delete from categories_contests where category_id = #{src.id}")
        flash.now[:notice] = "Moved #{count} contests from #{src.name} to #{dest.name}"
      else
        flash.now[:notice] = "Select a different Category to move to!"
      end
    end
  end

  def remap_brands
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless logged_in?(:super_admin)
    dest = nil
    if request.post? && (src = Brand.find(params[:src].to_i) rescue nil) && (params[:dest].blank? || (dest = Brand.find(params[:dest].to_i) rescue nil))
      if dest.nil? || src.id != dest.id
        count = src.contests.count
        Contest.update_all(['brand_id = ?', (dest.nil? ? nil : dest.id)], ['brand_id = ?', src.id])
        flash.now[:notice] = "Moved #{count} contests from #{src.name} to #{(dest.name rescue 'none')}"
      else
        flash.now[:notice] = "Select a different Brand to move to!"
      end
    end
  end

  def remap_skins
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless logged_in?(:super_admin)
    if request.post? && (src = Skin.find(params[:src].to_i) rescue nil) && (dest = Skin.find(params[:dest].to_i) rescue nil)
      if src.id != dest.id
        if src.contest_type == dest.contest_type
          count = src.contests.count
          Contest.update_all(['skin_id = ?', dest.id], ['skin_id = ?', src.id])
          flash.now[:notice] = "Moved #{count} contests from #{src.name} to #{dest.name}"
        else
          flash.now[:notice] = "Cannot move #{src.contest_type} to a skin for #{dest.contest_type.pluralize}"
        end
      else
        flash.now[:notice] = "Select a different Skin to move to!"
      end
    end
  end

end
