require File.dirname(__FILE__) + '/../test_helper'

class PredictionTest < Test::Unit::TestCase
  fixtures :users, :categories, :contests, :question_options, :questions, :credit_transactions

  def test_place_bet
    contest = contests(:prediction)
    user = users(:a_user)
    prize_points = user.prize_points
    response = user.responses.create!(:contest_id => contest.id)
    option = question_options(:prediction_option1)
    assert response.bets.create(:option_id => option.id, :wager => 100)
    assert_equal prize_points - 100, user.prize_points
    response.reload
    assert_equal -100, response.score

    bet = response.bets.build(:option_id => option.id, :wager => 2401)
    assert !bet.valid?
    assert bet.errors.on_base

    user2 = users(:another_user)
    response2 = user2.responses.create!(:contest_id => contest.id)
    assert_equal 80, user2.prize_points
    bet = response2.bets.build(:option_id => option.id, :wager => 10)
    assert !bet.valid?
    assert_equal 'Insufficient balance', bet.errors.on_base

    user2.credit_transactions.create!(:amount => 100, :description => 'foo')
    option2 = question_options(:prediction_option2)
    assert response2.bets.create(:option_id => option2.id, :wager => 10)

    assert_equal 10, option2.reload.total_wager
    assert_equal 100, option.reload.total_wager

    assert_equal (10.0/100.0) + 1, option.odds
    assert_equal (100.0/10.0) + 1, option2.odds

    question = questions(:prediction_question)
    assert question.open?
    question.update_attribute(:ends_on, Time.now - 1.second)
    assert !question.open?
    bet = response.bets.create(:option_id => option.id, :wager => 100)
    assert_equal 'Sorry Bets Closed!', bet.errors.on_base

    assert !question.declared?
    assert question.declare(option2, users(:an_admin))
    assert question.declared?
    assert !question.settled?
    
    question.settle
    question.reload
    assert !question.declare(option, users(:an_admin)) # cannot re-declare once settled
    assert question.settled?
    assert_equal -100, response.score
    assert_equal 100, response2.reload.score
    assert_equal 280, user2.prize_points
  end

end
