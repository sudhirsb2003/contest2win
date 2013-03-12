class HangmanController < ContestsController
  before_filter :login_required, :only => [:edit, :new, :add_question, :edit_question]
  before_filter :check_editable, :only => [:edit]

  layout 'application'

  def edit
    @contest = Hangman.find(params[:id])
    case request.method
    when :post
      @contest.attributes = params[:contest]
      if @contest.save
        @contest.add_audit_log(AuditLog::EDITED, current_user)
        flash[:notice] = 'Hangman updated!'
        return redirect_to(contest_url(@contest.url_attributes))
      else
        flash[:message] = 'Could not save the hangman!'
      end  
    end
  end

  def new
    case request.method
    when :post
      @contest = Hangman.new(params[:contest])
      @contest.user_id = current_user.id
      @contest.status = Contest::DEFAULT_STATUS
      if @contest.save
        flash[:notice] = "Your #{@contest.class} was saved. It\'ll be available online right after we review it."
        return redirect_to(contest_url(@contest.url_attributes(:action => 'add_question')))
      end
    when :get
      @contest = Hangman.new
    end 
  end

  # Redirects to the first pending Question depending
  # on the user's status.
  def play
    @contest_response = get_my_latest_response(@contest.id)
    if @contest_response
      unless @question = @contest_response.find_un_answered_question()
        respond_to do |format|
          #format.html { redirect_to contest_url(@contest.url_attributes(:action => 'finished')) and return }
          format.html { @finished = true}
          format.xml { render :xml => @contest_response.to_xml and return}
          format.js { 
            render :update do |page|
              page.redirect_to contest_url(@contest.url_attributes(:action => 'finished'))
            end
            return
          }
        end
      end
	  @fill_in_the_blanks = @question.fill_in_the_blanks(@contest_response.guesses_as_string(@question.id)) if @question
    else 
      @question = @contest.questions.find(:first) 
      @fill_in_the_blanks = @question.fill_in_the_blanks() if @question
      @contest_response = @contest.responses.new
    end
    respond_to do |format|
      format.html { render :layout => 'contest' }
      format.xml { render :xml => @question.to_xml(:base_url => request.host_with_port, :fill_in_the_blanks => @fill_in_the_blanks, :points_available => @contest_response.possible_score(@question.id),
		  		:guesses_right => @contest_response.guesses.find(:all, :conditions => "question_id = #{@question.id} and correct is true").map(&:value),
				:guesses_wrong => @contest_response.guesses.find(:all, :conditions => "question_id = #{@question.id} and correct is false").map(&:value))}
      format.js { render :action => 'play.rjs' }
    end
  end

  # Records the answer submited if it wasn't previously answered as a part of the user's
  # current response.
  def answer
    @contest_response = get_my_latest_response(@contest.id, true)
    value = params[:guess][:value].nil? ? '' : params[:guess][:value].upcase
    @guess = @contest_response.guesses.find_by_question_id_and_value(params[:guess][:question_id], value)
    if @guess.nil? && @contest_response.answers.find_by_question_id(params[:guess][:question_id]).nil?
	    @guess = @contest_response.guesses.build(params[:guess])
      unless @guess.save
        respond_to do |format|
          render :xml => @guess.errors.to_xml and return
        end
      end

	    @fill_in_the_blanks = @guess.question.fill_in_the_blanks(@contest_response.guesses_as_string(@guess.question_id))
	    if finished_question = @contest_response.finished_question(@guess.question_id)
        answer = @contest_response.answers.build({:question_id => @guess.question_id, :correct => true})		
        answer.points = @contest_response.possible_score(@guess.question_id)
        answer.save!
        @contest_response.reload
      end	
    end
    respond_to do |format|
      format.js { render :action => 'answer' }
      format.xml { render :xml => finished_question ? @contest_response.to_xml : @guess.to_xml }
    end  
  end

  def skip
    @contest_response = get_my_latest_response(@contest.id, true)
    answer = @contest_response.answers.create({:question_id => params[:question_id], :correct => false})
    @contest_response.reload
    respond_to do |format|
      format.html {redirect_to contest_url(@contest.url_attributes(:action => 'play'))}
      #format.xml { render :xml => {:answer => answer.question.answer}.to_xml(:root => 'skip')}
      format.xml { render :xml => @contest_response.to_xml}
    end  
  end

  # Starts a new game...
  def play_again
    if logged_in?
      @contest_response = @contest.responses.create({:user_id => current_user.id})
    else
      @contest_response = @contest.responses.create({:session_id => session_uuid})
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
        #correct_option = params[:correct_option]
        params[:options].each_value { |option| @question.options.build(option) } unless params[:options].nil?
        @question.options.first.points = 7

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
        @question.options.build(:points => 7)
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
      redirect_to contest_url(@question.contest.url_attributes(:action => 'questions'))
    when 'Edit'
      redirect_to contest_url(@question.contest.url_attributes(:action => 'edit_question', :question_id => @question.id))
    else
      redirect_to contest_url(@question.contest.url_attributes(:action => 'add_question'))
    end
  end

  def edit_question
    @question = Question.find(params[:question_id])
    return render(:template => 'shared/access_denied', :status => :unauthorized) \
          unless @question.editable?(current_user)

    @contest = @question.contest
    case request.method
    when :post
      @question.attributes = params[:question]
      @question.add_or_update_options(params[:options])
      @question.status = Question::STATUS_DRAFT

			begin
        Question.transaction do
          @question.valid?
          if @video = @question.set_video(params[:video])
            @video.save!
          end  
          @question.save!
        end
        return redirect_to contest_url(
              @question.contest.url_attributes(:action => 'preview_question', :question_id => @question.id,
              :controller => 'hangman'))
      rescue
        flash[:notice] = "Failed to save the question!"
      end

    end  
      
  end

  def preview_question
    @question = @contest.all_questions.find(params[:question_id])
  end
  
#  def feed
#    hangman = Hangman.find(params[:id])
#    version = "2.0"
#    content = RSS::Maker.make(version) do |m|
#      m.channel.title = "C2W: #{hangman.title}"
#      m.channel.description = hangman.description
#      m.channel.link = contest_url(hangman.url_attributes)
#      hangman.questions.find(:all, :order => 'id desc', :limit => 10).each do |question|
#        i = m.items.new_item
#        i.title = "#{question.question}: by #{question.user.username}"
#        i.link = contest_url(hangman.url_attributes(:question_id => question.id))
#        i.date = question.created_on
#      end
#    end
#    render :text => content.to_s
#  end

  # Adds an option to the form 
  def add_option
    @option = QuestionOption.new
  end

  def questions
     if logged_in?(:admin)
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

end
