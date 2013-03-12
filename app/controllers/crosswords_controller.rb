class CrosswordsController < ContestsController
  before_filter :login_required, :only => [:edit, :new, :add_questions]
  before_filter :check_editable, :only => [:edit]

  def edit
    case request.method
    when :post
      @contest.attributes = params[:contest]
      if @contest.save
        @contest.add_audit_log(AuditLog::EDITED, current_user)
        flash[:notice] = 'Crossword updated!'
        return redirect_to(contest_url(@contest.url_attributes))
      else
        flash[:message] = 'Could not save the crossword!'
      end  
    end
  end

  def new
    case request.method
    when :post
      @contest = Crossword.new(params[:contest])
      @contest.user_id = current_user.id
      @contest.status = Contest::STATUS_DRAFT
      if @contest.save
        flash[:notice] = "Your #{@contest.class} was saved. It\'ll be available online right after we review it."
        return redirect_to(contest_url(@contest.url_attributes(:action => 'add_questions')))
      end
    when :get  
      @contest = Crossword.new
    end 
  end

  def play
    if @contest.draft? || @contest.approval_pending?
      return redirect_to(contest_url(@contest.url_attributes(:action => 'solution')))
    end  

    @contest_response ||= get_my_latest_response(@contest.id)
    if @contest_response && @contest_response.completed?
      respond_to do |format|
        format.html { return render :layout => 'contest' }
        format.xml {return render :template => 'crosswords/play'}
        format.js { 
          render :update do |page|
            page.redirect_to contest_url(@contest.url_attributes)
          end
          return
        }
      end
    end
    @contest_response = @contest.responses.build unless @contest_response
    respond_to do |format|
      format.html { return render :layout => 'contest' }
      format.xml {return render :template => 'crosswords/play'}
    end
  end

  def contest_response
    @contest_response = get_my_latest_response(@contest.id, false) || @contest.responses.build
    respond_to do |format|
      format.html { render :nothing => true}
      format.xml { render :xml => @contest_response.to_xml}
    end
  end

  # Records the answer submited if it wasn't previously answered as a part of the user's
  # current response.
  def answer
    @contest_response = get_my_latest_response(@contest.id, true)
    return play if @contest_response.completed?

    # we don't want guys changing their answers!
    if @contest_response.answers.find_by_question_id(params[:question_id]).nil?
      question = @contest.questions.find(params[:question_id])
      if question && question.answer == params[:answer]
        ans = @contest_response.answers.build(:question_id => params[:question_id])
        option = question.options.first
        ans.question_option_id = option.id
        ans.points = option.points_to_award
        ans.correct = option.correct?
        unless ans.save
          respond_to do |format|
            render :xml => ans.errors.to_xml and return
          end
        end
        @contest_response.reload
      end
    end  
    respond_to do |format|
      format.js {
        if @contest_response.completed?
          render :update do |p|
            p.redirect_to(contest_url(@contest.url_attributes))
            return
          end  
        else  
          return render :nothing => true
        end
      }
      format.xml {return render :xml => @contest_response.to_xml }
    end
  end

  def give_up_all
    return render(:template => 'shared/access_denied') if @contest.locked?

    @contest_response = get_my_latest_response(@contest.id, true)
    questions = @contest_response.find_un_answered_questions
    answers = []
    questions.each do |q|
      ans = @contest_response.answers.build(:question_id => q.id)
      ans.save
      answers << {:question_id => q.id, :answer => q.answer}
    end
    respond_to do |format|
      format.js {
        render :update do |p|
          p.redirect_to(contest_url(@contest.url_attributes))
        end  
      }
      format.xml { render :xml => answers.to_xml(:skip_types => true, :root => 'give-up')}
    end
  end

  def give_up
    return render(:template => 'shared/access_denied') if @contest.locked?
    @contest_response = get_my_latest_response(@contest.id, true)
    question = @contest.questions.find(params[:question_id])
    ans = @contest_response.answers.build(:question_id => params[:question_id])
    ans.save
    @contest_response.reload
    clue = CrosswordClue.find_by_question_id(params[:question_id])
    respond_to do |format|
      format.js {
        if @contest_response.completed?
          render :update do |p|
            p.redirect_to(contest_url(@contest.url_attributes))
          end  
        else  
          render :update do |p|
            #p.call 'give_up', question.answer, clue.row, clue.col, clue.across
            p.call 'give_up_response', question.answer, question.id
          end
        end
      }
      format.xml { render :xml => {:answer => question.answer}.to_xml(:root => 'give-up')}
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

  def add_questions
    unless @contest.questions_editable?(current_user)
      return render(:template => 'shared/access_denied')
    end  
    @questions = []
    if request.get?
      if @contest.all_questions.empty?
        10.times {@questions << CrosswordQuestion.new({:answer => ''})}
      else
        @questions = @contest.all_questions
      end  
    else
      all_question_ids = @contest.all_question_ids
      errors = false
      params[:questions].each_value { |p_question|
        if all_question_ids.include? p_question[:id].to_i
            question = @contest.all_questions.find(p_question[:id])
            question.attributes = p_question
            question.status = Question::STATUS_DRAFT
            question.save
        else
          question = CrosswordQuestion.new(p_question)
          question.user_id = current_user.id
          question.status = Question::STATUS_DRAFT
          @contest.all_questions << question
        end
        @questions << question
        unless question.errors.empty?
          errors = true
        end
      }
      if @questions.size < 10
        errors = true
        @contest.errors.add_to_base('You need to have atleast 10 words!')
      end  
      unless errors
        @contest.generate
        return redirect_to(contest_url(@contest.url_attributes(:action => :preview)))
      end  
    end  
    @questions.sort!{|x,y| x.answer <=> y.answer}
    render :action => :add_questions
  end

  alias add_question add_questions

  # add more clues to the questions 
  def add_more
    render :update do |page|
      page.replace 'more_clues', :partial => 'add_more', :locals => {:index => params[:index].to_i, :question => CrosswordQuestion.new}
    end
  end

  def confirm
    unless @contest.editable?(current_user)
      return render(:template => 'shared/access_denied')
    end  

    case params[:commit]
    when 'Done!'
      @contest.questions.each{|q| q.update_attribute(:status, Question::STATUS_APPROVAL_PENDING)}
      @contest.finished_creating
      flash[:notice] = 'Thanks for your entry. Your crossword has been saved and will be available online shortly (after we do a quick review).'
      return redirect_to(contest_url(@contest.url_attributes(:action => :play)))
    when 'Edit'
      return redirect_to(contest_url(@contest.url_attributes(:action => :add_questions)))
    end
  end

  def preview  
    unless @contest.questions_editable?(current_user)
      return render(:template => 'shared/access_denied')
    end
  end

  def solution
    unless @contest.solution_viewable?(current_user)
      return render(:template => 'shared/access_denied')
    end
    render :layout => 'contest', :action => :solution
  end
  alias questions solution

  def finished
    render :action => :play
  end

end

