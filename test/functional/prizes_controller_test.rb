require File.dirname(__FILE__) + '/../test_helper'
require 'prizes_controller'
require 'user'
require 'question'

# Re-raise errors caught by the contrrizeer.
class PrizesController; def rescue_action(e) raise e end; end

class PrizesControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :prizes, :contest_prizes, :short_listed_winners, :credit_transactions

  def setup
    @controller = PrizesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_redeem_not_redeemable
    prize = prizes(:cash)
    assert !prize.redeemable?
    assert !prize.redeemable_by_user?(users(:a_user))
    pp = users(:a_user).prize_points
    dispatch = { :mobile_number => '090909890', :pin_code => '400057', :address_line_1 => '23 pari',
      :phone_number => '434343', :city => 'Mumbai', :state => 'Maharashtra', :country => 'India'
    }
    post :redeem,
      {:username => users(:a_user).username, :id => prize.id, :dispatch => dispatch, :password => 'jim277'},
      {:user => users(:a_user) }
    assert_redirected_to :action => :show, :id => prize.id
    assert_equal "Sorry, this prize is not redeemable!", flash[:notice]
  end

  def test_redeem_not_enough_pp
    prize = prizes(:ferrari)
    assert prize.redeemable?
    assert !prize.redeemable_by_user?(users(:a_user))
    pp = users(:a_user).prize_points
    dispatch = { :mobile_number => '090909890', :pin_code => '400057', :address_line_1 => '23 pari',
      :phone_number => '434343', :city => 'Mumbai', :state => 'Maharashtra', :country => 'India'
    }
    post :redeem,
      {:username => users(:a_user).username, :id => prize.id, :dispatch => dispatch, :password => 'jim277'},
      {:user => users(:a_user) }
    assert_redirected_to :action => :show, :id => prize.id
    assert_equal "Sorry, you don't have enough Prize Points to redeem this prize!", flash[:notice]
  end

  def test_redeem_no_tds
    prize = prizes(:ipod_sans_tds)
    assert prize.redeemable?
    assert prize.redeemable_by_user?(users(:a_user))
    pp = users(:a_user).prize_points
    dispatch = { :mobile_number => '090909890', :pin_code => '400057', :address_line_1 => '23 pari',
      :phone_number => '434343', :city => 'Mumbai', :state => 'Maharashtra', :country => 'India'
    }
    post :redeem,
      {:username => users(:a_user).username, :id => prize.id, :dispatch => dispatch, :password => 'jim277'},
      {:user => users(:a_user) }
    assert assigns['dispatch']
    assert assigns['dispatch'].id
    assert assigns['dispatch'].errors.empty?
    assert_equal Dispatch::STATUSES[:pending_shipment], assigns['dispatch'].status
    assert_equal users(:a_user).prize_points, pp - prize.credits
  end

  def test_redeem_tds
    prize = prizes(:ipod)
    assert prize.redeemable?
    assert prize.redeemable_by_user?(users(:a_user))
    pp = users(:a_user).prize_points
    dispatch = { :mobile_number => '090909890', :pin_code => '400057', :address_line_1 => '23 pari',
      :phone_number => '434343', :city => 'Mumbai', :state => 'Maharashtra', :country => 'India'
    }
    post :redeem,
      {:username => users(:a_user).username, :id => prize.id, :dispatch => dispatch, :password => 'jim277'},
      {:user => users(:a_user) }
    assert assigns['dispatch']
    assert assigns['dispatch'].id
    assert assigns['dispatch'].errors.empty?
    assert_equal Dispatch::STATUSES[:awaiting_payment], assigns['dispatch'].status
    assert_equal users(:a_user).prize_points, pp - prize.credits
  end

end
