# --$Id: response.rb 897 2008-01-02 15:18:09Z ngupte $--
#
# Response for a Hangman.
#
class HangmanResponse < Response
  has_many :guesses, :order => :id, :foreign_key => 'response_id', :dependent => :delete_all

  def guesses_as_string(question_id)
	@guesses_as_string ||= guesses.find_all_by_question_id(question_id).collect{|a| a.value}.to_s
  end

  def finished_question(question_id)
	  correct_guesses = guesses.find(:all, :conditions => "question_id = #{question_id} and correct is true").collect{|a| a.value}.to_s
  	ans = Question.find(question_id).answer.upcase.gsub(/\W|_/,'')
	  ans.each_char {|a| return false unless correct_guesses.index(a) }	
	  return true
  end

  def possible_score(question_id)
	points = Question.find(question_id).correct_option.points
  	points -= guesses.count(:conditions => "question_id = #{question_id} and correct is false")
    points = 0 if points < 0;
	return points
  end

end
