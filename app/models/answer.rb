# --$Id: answer.rb 2740 2008-12-29 10:21:49Z ngupte $--
#
# An answer is what a user submits to a Question within a Contest.
# <tt>Answer</tt>s for one contest make up the Response to that contest.
#
class Answer < ActiveRecord::Base
  belongs_to :response, :counter_cache => true
  belongs_to :question
  belongs_to :entry
  belongs_to :option, :class_name => 'QuestionOption', :foreign_key => :question_option_id
  attr_protected :points

  def before_create() calculate_loyalty_points end

  def validate_on_create
    if question_option_id
      errors.add_to_base("Invalid option!") unless question.options.exists?(question_option_id)
    end  
  end

  def correct?
    option && option.correct?
  end

  def after_create
    response.update_attribute(:finished_on, Time.now)
    response.guesses.delete_all if response.contest.is_a?(Hangman)
    # update the net score of the corresponding response
    contest = response.contest
    unless contest.ended?
      unless points == 0
        connection.execute <<-SQL, 'Update response based on answer'
          UPDATE responses set score = score + #{points}
          #{',correct_answers_count = correct_answers_count + 1' if correct?}
          WHERE id = #{response_id}
        SQL
      end
    end

    if contest.is_a?(PersonalityTest) && response.answers_count + 1 == response.contest.questions.count
      #response.personality.increment!(:number_of_users)
      if(personality = contest.personality_for_score(response.score+points))
        personality.increment!(:number_of_users)
      end
    end   
  end

  def fill_in_the_blanks
    question.fill_in_the_blanks(response.guesses_as_string(question_id))
  end

  def to_xml(options = {})    
    super do |x|
      if response.contest.is_a?(Hangman)
        x.answer question.answer
      elsif response.contest.is_a?(Quiz)
        x.answer question.correct_option.id
      end
    end
  end

  # Deletes answers of unlogged-in users which are older than a day
  def self.delete_old_answers
    connection.execute <<-SQL, 'Deleting old answers'
      DELETE FROM answers WHERE answers.response_id IN
	    (SELECT id FROM responses WHERE created_on < now() - interval '1 day' AND user_id is null);
    SQL
  end

  private
  def calculate_loyalty_points
    if (correct || !response.contest.scorable?) && response.user && response.contest.loyalty_points_applicable?
      unless response.user.answers.find(:first,
            :conditions => "responses.contest_id = #{response.contest_id} and question_id = #{question_id} and loyalty_points is not null")
        write_attribute(:loyalty_points, AppConfig.prize_points_per_right_answer)
        write_attribute(:user_id, response.user_id)
      end
    end
  end
end
