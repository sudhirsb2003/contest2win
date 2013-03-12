require File.dirname(__FILE__) + '/../test_helper'

class ContestPrizeTest < Test::Unit::TestCase
  fixtures :users, :contests, :contest_prizes, :short_listed_winners, :responses

  def test_started
    assert contest_prizes(:one).started?
    assert !contest_prizes(:two).started?
  end

  def test_ended
    assert !contest_prizes(:one).ended?
    contest_prizes(:one).update_attribute(:to_date, Time.now - 1.days)
    assert contest_prizes(:one).ended?
    assert !contest_prizes(:two).ended?
  end

  def test_prizes_left
    assert_equal 2, contest_prizes(:one).quantity
    assert_equal 1, contest_prizes(:one).count_prizes_left
  end

  # Gets 3 indian users and ignores the us user
  def test_top_scorers_boundary_checks
    top_scorers = contest_prizes(:boundary).top_scorers.to_a
    assert_equal 3, top_scorers.size
    assert_equal 1000, top_scorers[0]['score'].to_i
    assert_equal 800, top_scorers[1]['score'].to_i
  end

end
