class Bet < ActiveRecord::Base
  DEFAULT_AMOUNTS = [10, 25, 50, 100]
  #MAX_WAGER_PER_QUESTION = 200
  MINIMUM_BALANCE = 80
  belongs_to :response
  belongs_to :option, :class_name => 'QuestionOption', :foreign_key => :option_id

  validates_numericality_of :wager, :only_integer => true, :greater_than => 0

  def validate
    unless errors.invalid? :wager
      errors.add_to_base("Insufficient balance") if wager > response.user.prize_points - MINIMUM_BALANCE
      if (response.bets.sum(:wager, :conditions => ['option_id in (?)', option.question.option_ids]) + wager > question.betting_limit)
        errors.add_to_base("You cannot bet more than #{question.betting_limit} on this question.")
      end
    end
    errors.add_to_base("Sorry Bets Closed!") unless option.question.open?
  end

  before_create :set_user_id
  after_create :debit_prize_points, :update_stats

  def payout
    wager * option.odds
  end

  def question
    option.question
  end

  private

  def debit_prize_points
    response.user.debit_account(wager, "Placed bet on #{option.title} (#{id})")
  end

  def update_stats
    QuestionOption.update_all(['clicks = clicks + ?', wager], ['id = ?', option_id])
    Question.update_all(['total_rating = total_rating + ?', wager], ['id = ?', option.question_id])
    Response.update_all(['score = score - ?', wager], ['id = ?', response_id])
  end

  def set_user_id
    self.user_id = response.user_id
  end

end
