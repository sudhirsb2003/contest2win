class PersonalityTestsController < QuizzesController
  before_filter :login_required, :only => [:edit, :new, :add_question, :edit_question]
  before_filter :check_editable, :only => [:edit]

  before_filter(:disable, :only => [:new, :edit, :delete, :add_question, :edit_question, :edit_personality, :update_personality, :add_personality, :delete_personality])

  def personalities
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless (current_user?(@contest.user) || logged_in?(:moderator))
    render :layout => 'contest' unless @contest.draft?
  end

  def edit_personality
    @personality = @contest.personalities.find(params[:personality_id])
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless @personality.editable?(current_user) 
  end

  def update_personality
    @personality = @contest.personalities.find(params[:personality_id])
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless @personality.editable?(current_user) 
    if @personality.update_attributes params[:personality]
      redirect_to @contest.url_attributes(:action => :personalities)
    else
      render :action => :edit_personality
    end
  end

  def add_personality
    return render(:template => 'shared/access_denied', :status => :unauthorized) \
          unless @contest.personality_addable?(current_user)
    @personality = @contest.personalities.create(params[:personality])
    if @personality.save
      return redirect_to @contest.url_attributes(:action => :personalities)
    end
    render :action => :personalities
  end

  def new
    case request.method
    when :post
      @contest = PersonalityTest.new(params[:contest])
      @contest.user_id = current_user.id
      @contest.status = Contest::DEFAULT_STATUS
      if @contest.save
        flash[:notice] = "Your #{@contest.class} was saved. It\'ll be available online right after we review it."
        return redirect_to(contest_url(@contest.url_attributes(:action => :personalities)))
      end
    when :get  
      @contest = PersonalityTest.new
    end 
  end

  def delete_personality    
    personality = @contest.personalities.find(params[:personality_id])
    if personality.deletable?(current_user)
      @contest.personalities.find(params[:personality_id]).destroy
    end
    render :nothing => true
  end

end
