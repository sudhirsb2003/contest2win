class QuestionOption < ActiveRecord::Base

  # validations 
  validates_numericality_of :points, :maximum => 200
  validates_size_of :text, :maximum => 100

  # associations 
  belongs_to :question
  belongs_to :entry
  has_many :answers
  acts_as_list :scope => :question
  attr_protected :question_id, :clicks

  # Gets the value from db or evaluates. Evaluation is applicable only for Quiz and non scorable contests
  def correct?
    (contest.is_a?(Quiz)) ? points > 0 : true
  end

  def points_to_award
    points
  end

  # Score is the percentage of answers that have selected this option
  def score
    question.answers_count > 0 ? clicks * 100.0 / question.answers_count : 0
  end

  def score_for_entry
    @score_for_entry ||= begin
      other_entry = question.entries.find(:first, :conditions => "entries.id != #{entry_id}")
      entry_score = RankedEntry.count(:joins => "inner join ranked_entries r2 on ranked_entries.faceoff_id = #{question.contest_id} and r2.faceoff_id = #{question.contest_id}
          and ranked_entries.response_id = r2.response_id and ranked_entries.entry_id = #{entry_id} and r2.entry_id = #{other_entry.id}",
          :conditions => 'ranked_entries.points > r2.points')
      total_count = RankedEntry.count(:joins => "inner join ranked_entries r2 on ranked_entries.faceoff_id = #{question.contest_id} and r2.faceoff_id = #{question.contest_id}
          and ranked_entries.response_id = r2.response_id and ranked_entries.entry_id = #{entry_id} and r2.entry_id = #{other_entry.id}")
      entry_score * 100.0 / total_count
    end  
  end

  # pool is the total wagered on all other options
  def pool
    question.total_wager - total_wager
  end

  def total_wager() clicks end

  def odds
    raise 'Division by zero' if total_wager == 0
    1 + (pool.to_f/total_wager)
  end

  def before_save
    self.text.upcase! if question.contest.is_a?(Hangman)
  end

  def title
    "#{question.question}/#{text}"
  end

  def top_bettors(limit = 9)
    sql = "SELECT user_id, sum(wager) as total_bet, sum(wager) * #{odds} as payout from bets where option_id = #{id} group by user_id order by total_bet desc limit #{limit}"
    connection.execute(sql)
  end

  private
  def contest
    @contest ||= question.contest
  end

end
