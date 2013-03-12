require File.dirname(__FILE__) + '/../test_helper'

class ShortListedTest < Test::Unit::TestCase
  fixtures :users, :contests, :prizes, :contest_prizes, :short_listed_winners

  def test_expired
    short_listed_winner = short_listed_winners(:expired)
    assert short_listed_winner.confirm_by_date < Date.today.to_time
    assert !short_listed_winner.confirmed?
    assert !short_listed_winner.rejected?
    assert short_listed_winner.expired?
    assert !short_listed_winner.pending?
    assert_equal 'Expired', short_listed_winner.status
  end

  def test_almost_expired
    short_listed_winner = short_listed_winners(:almost_expired)
    assert short_listed_winner.confirm_by_date.to_date == Date.today
    assert !short_listed_winner.confirmed?
    assert !short_listed_winner.rejected?
    assert !short_listed_winner.expired?
    assert short_listed_winner.pending?
    assert_equal 'Pending', short_listed_winner.status
  end

  def test_accepted
    short_listed_winner = short_listed_winners(:accepted)
    assert short_listed_winner.confirmed?
    assert !short_listed_winner.rejected?
    assert !short_listed_winner.expired?
    assert !short_listed_winner.pending?
    assert_equal 'Accepted', short_listed_winner.status
  end

  def test_rejected
    short_listed_winner = short_listed_winners(:rejected)
    assert short_listed_winner.confirmed?
    assert short_listed_winner.rejected?
    assert !short_listed_winner.expired?
    assert !short_listed_winner.pending?
    assert_equal 'Rejected', short_listed_winner.status
  end

end
