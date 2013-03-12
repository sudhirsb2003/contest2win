class QuizzesController < ContestsController
  before_filter :login_required, :only => [:edit, :new, :add_question, :edit_question]
  before_filter :check_editable, :only => [:edit]
  before_filter(:disable,
      :only => [:new, :edit, :delete, :finished_creating, :add_comment, :delete_comment, :toggle_favourite, :vote,
        :edit_question, :add_question, :confirm_question, :add_option, :add_entry, :edit_entry, :confirm_entry, :delete_entry, :add_questions, :confirm ])


  def edit
    case request.method
    when :post
      @contest.attributes = params[:contest]
      if @contest.save
        @contest.add_audit_log(AuditLog::EDITED, current_user)
        flash[:notice] = "#{@contest.class} updated!"
        return redirect_to(contest_url(@contest.url_attributes))
      else
        flash[:message] = 'Could not save the quiz!'
      end  
    end
  end

  def questions
    if logged_in?(:moderator)
       @questions = @contest.all_questions.paginate(:page => params[:page], :per_page => 10, :order => 'id asc')
    else
       conditions = "(questions.status = #{Question::STATUS_LIVE}"
       conditions << " or questions.user_id = #{current_user.id}" if current_user
       conditions << ')'
       @questions = @contest.all_questions.paginate(:conditions => conditions,
           :page => params[:page], :per_page => 10, :order => 'id asc')
    end  
    render :layout => 'contest'
  end

  def new
    case request.method
    when :post
      @contest = Quiz.new(params[:contest])
      @contest.user_id = current_user.id
      @contest.status = Contest::DEFAULT_STATUS
      if @contest.save
        flash[:notice] = "Your #{@contest.class} was saved. It\'ll be available online right after we review it."
        return redirect_to(contest_url(@contest.url_attributes(:action => 'add_question')))
      end
    when :get  
      @contest = Quiz.new
    end 
  end

  # Redirects to the first pending Question depending
  # on the user's status.
  def play
    @contest_response ||= get_my_latest_response(@contest.id)
    if @contest_response
      unless @question = @contest_response.find_un_answered_question()
        respond_to do |format|
          #format.html { redirect_to contest_url(@contest.url_attributes(:action => 'finished')) and return }
          format.html { @finished = true}
          format.xml { render :xml => @contest_response.to_xml(:base_url => request.host_with_port) and return}
          format.js { 
            render :update do |page|
              page.redirect_to contest_url(@contest.url_attributes(:action => 'finished'))
            end
            return
          }
        end
      end
    else 
       @question = @contest.questions.find(:first) 
    end
    respond_to do |format|
      format.html { return render :layout => 'contest' }
      format.xml { render :xml => @question.to_xml({:base_url => request.host_with_port}) }
      format.js { render :action => 'play.rjs' }
    end
  end

  # Records the answer submited if it wasn't previously answered as a part of the user's
  # current response.
  def answer
    @contest_response = get_my_latest_response(@contest.id, true)
    return play if @contest_response.completed?

    ans_attr = {:question_id => params[:question_id]}
    ans_attr[:question_option_id] = params[:answer][:question_option_id] if params[:answer] && 'Skip' != params[:commit] 
    if ans = @contest_response.add_answer(ans_attr)
      unless ans.errors.empty?
        respond_to do |format|
          render :xml => ans.errors.to_xml and return
        end
      end
    end  
    respond_to do |format|
      format.html { redirect_to contest_url(@contest.url_attributes(:action => 'play')) }
      format.js { play }
      format.xml { return render(:xml => @contest_response.to_xml(:base_url => request.host_with_port)) }
    end  
  end

  # Starts a new game...
  def play_again
    if logged_in?
      @contest_response = Response.create({:contest_id => @contest.id, :user_id => current_user.id})
    else
      @contest_response = Response.create({:contest_id => @contest.id, :session_id => session_uuid})
    end  
    respond_to do |format|
      format.html {redirect_to contest_url(@contest.url_attributes(:action => 'play'))}
      format.xml {return play}
    end  
  end

  def add_question
    return render(:template => 'shared/access_denied', :status => :unauthorized) \
          unless @contest.questions_addable?(current_user)
    case request.method
      when :post
        @question = @contest.questions.build(params[:question])
        @question.user = current_user
        @question.status = Question::STATUS_DRAFT
        # the set the correct option's points to 1
        unless params[:options].nil? 
          params[:options].each_value { |option|
              option = @question.options.build(option)
              option.points = 0 unless @contest.is_a?(PersonalityTest) or logged_in?(:admin)
          }
        end
        unless logged_in?(:admin)
          if correct_option = params[:correct_option]
            @question.options[correct_option.to_i].points = 1
          end  
        end  
        begin
          Question.transaction do
            @question.valid?
            if @video = @question.set_video(params[:video])
              @video.save!
            end  
            @question.save!
          end
          return redirect_to(contest_url(@contest.url_attributes(:action => 'preview_question', :question_id => @question.id)))
        rescue
          flash[:message] = 'Could not save the question!'
        end  
      when :get
        @question = Question.new
        @question.contest = @contest
        3.times {@question.options.build} # put 3 options for the question
      end
  end

  def confirm_question
    @question = @contest.all_questions.find(params[:question_id])
    unless @question && @question.editable?(current_user)
      return render(:template => 'shared/access_denied')
    end  

    if params[:commit] != 'Edit'
      @question.update_attribute(:status, Question::STATUS_APPROVAL_PENDING)
      flash[:notice] = 'Thanks for your entry. Your question has been saved and will be available online shortly (after we do a quick review).'
    end  
    case params[:commit]
    when 'Done!'
      @contest.finished_creating
      return redirect_to(contest_url(@question.contest.url_attributes(:action => :questions)))
    when 'Edit'
      return redirect_to(contest_url(@question.contest.url_attributes(:action => :edit_question,
                                                                      :question_id => @question.id)))
    else
      return redirect_to(contest_url(@question.contest.url_attributes(:action => :add_question)))
    end
  end

  def edit_question
    @question = @contest.all_questions.find(params[:question_id])
    unless @question.editable?(current_user)
      return render(:template => 'shared/access_denied', :status => :unauthorized)
    end
    case request.method
    when :post
      @question.attributes = params[:question]
      @question.add_or_update_options(params[:options])
      @question.status = Question::STATUS_DRAFT
      unless logged_in?(:admin)
        @question.options.each {|o| o.update_attribute(:points, 0)} unless @contest.is_a?(PersonalityTest)
        if correct_option = params[:correct_option]
          @question.options[correct_option.to_i].update_attribute(:points, 1)
        end  
      end
      begin
        Question.transaction do
          @question.valid?
          if @video = @question.set_video(params[:video])
            @video.save!
          end  
          @question.save!
        end
        return redirect_to(contest_url(@question.contest.url_attributes(:action => 'preview_question', :question_id => @question.id)))
      rescue
        flash[:notice] = "Failed to save the question!"
      end
    end  
  end

  def preview_question
    @question = Question.find(params[:question_id])
  end
  
  # Adds an option to the form 
  def add_option
    @option = QuestionOption.new
  end

end
