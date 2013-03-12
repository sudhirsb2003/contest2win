require File.dirname(__FILE__) + '/../test_helper'

class QuizTest < Test::Unit::TestCase
  fixtures :users, :categories

  def test_ends_on_never
    contest = Quiz.new(:title => 'title', :tag_list => 'test',
        :starts_on => Date.today.to_s, :never_ends => 'true')
    #assert contest.valid?
    assert_equal '2020-01-01', contest.ends_on.to_s
  end

  def test_ends_on_valid_by_admin
    contest = Quiz.new(:title => 'title', :tag_list => 'test',
        :starts_on => Date.today.to_s, :ends_on => (Date.today.to_time + 10.days).to_date.to_s)
    contest.user_id = users(:an_admin).id
    contest.valid?
    assert_equal (Date.today.to_time + 10.days).to_date.to_s, contest.ends_on.to_s
  end

end
