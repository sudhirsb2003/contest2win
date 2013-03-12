class QuestionsController < ApplicationController
  cache_sweeper :contests_sweeper, :only => [ :delete ]
  before_filter(:disable)

  def delete
    question = Question.find(params[:question_id])
    #if question.deletable?(current_user)
      question.soft_delete(current_user)
    #end
    render :nothing => true
  end

  def update
    @question = Question.find(params[:id])
    unless @question.editable?(current_user)
      return render(:template => 'shared/access_denied', :status => :unauthorized)
    end
    @question.attributes = params[:question]
    @question.add_or_update_options(params[:options])
    @question.options[params[:correct_option].to_i].points = 1
    @question.options[params[:correct_option].to_i].save
    if @question.save
      redirect_to @question.contest.path_for(:edit)
    else
      flash.now[:message] = "Could not save question!"
      render :template => :edit
    end  
  end

  def remove_option
    if QuestionOption.exists?(params[:id]) && option = QuestionOption.find(params[:id])
      if option.question.editable?(current_user)
        unless option.question.options.count <= 2
          QuestionOption.delete(option.id) 
          return render(:nothing => true)
        else
          return render :nothing => true, :status => :error
        end  
      else
        return access_denied
      end  
    end 
  end

end
