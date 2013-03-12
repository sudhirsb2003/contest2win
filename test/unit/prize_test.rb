require File.dirname(__FILE__) + '/../test_helper'

class PrizeTest < Test::Unit::TestCase
  fixtures :prizes, :users, :contests

  # Replace this with your real tests.
  def test_basic
    assert prizes(:ipod).needs_dd?
    assert !prizes(:ipod).prize_points?

    assert !prizes(:cash).needs_dd?
    assert prizes(:cash).prize_points?
    assert !prizes(:cash).redeemable_by_user?(users(:a_user))
  end

  def test_tds
    assert_equal 0, Prize.new(:value => 4999).tds
    assert_equal 1545, Prize.new(:value => 5000).tds
    assert_equal 1644.189.to_d, Prize.new(:value => 5321).tds.to_d
  end
end
