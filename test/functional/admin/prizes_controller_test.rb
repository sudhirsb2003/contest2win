require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/prizes_controller'
require 'user'

# Re-raise errors caught by the controller.
class Admin::PrizesController; def rescue_action(e) raise e end; end

class Admin::PrizesControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :prizes, :contest_prizes, :short_listed_winners, :responses

  def setup
    @controller = Admin::PrizesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_short_list_winners_when_prize_is_an_object
    contest_prize = contest_prizes(:boundary)
    assert contest_prize.short_listed_winners.empty?
    assert !contest_prize.prize.prize_points?
    get :top_scorers, {:id => contest_prize}, {:user => users(:an_admin)}
    assert_equal 3, assigns['top_scorers'].size
    top_scorers = assigns['top_scorers']
    ids = {:ids => top_scorers[0]['user_id']}
    post :short_list_winners, {:id => contest_prize.id, :ids => ids}, {:user => users(:an_admin)}
    assert_equal 1, contest_prize.short_listed_winners(true).size
    assert contest_prize.short_listed_winners.first.accepted.nil?
    assert contest_prize.short_listed_winners.first.confirmed_on.nil?
  end

  def test_short_list_winners_when_prize_is_credits
    contest_prize = contest_prizes(:credits)
    assert contest_prize.short_listed_winners.empty?
    assert contest_prize.prize.prize_points?
    get :top_scorers, {:id => contest_prize}, {:user => users(:an_admin)}
    assert_equal 3, assigns['top_scorers'].size
    top_scorers = assigns['top_scorers']
    ids = {:ids => top_scorers[0]['user_id']}
    post :short_list_winners, {:id => contest_prize.id, :ids => ids}, {:user => users(:an_admin)}
    assert_equal 1, contest_prize.short_listed_winners(true).size
    assert_equal true, contest_prize.short_listed_winners.first.accepted
    assert !contest_prize.short_listed_winners.first.confirmed_on.nil?
  end

  def test_short_list_winners_before_due_date
    contest_prize = contest_prizes(:premature)
    top_scorers = contest_prize.top_scorers.to_a
    assert_equal 4, top_scorers.size
    ids = {:ids => top_scorers[0][0]}
    post :short_list_winners, {:id => contest_prize.id, :ids => ids}, {:user => users(:an_admin)}
    assert contest_prize.short_listed_winners(true).empty?
    assert_response :redirect
    assert_equal 'This prize is not yet due to be declared!', flash[:notice]
  end

end
