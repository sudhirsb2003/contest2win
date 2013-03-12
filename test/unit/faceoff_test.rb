require File.dirname(__FILE__) + '/../test_helper'

class FaceoffTest < Test::Unit::TestCase
  fixtures :users, :contests

  def test_number_of_questions
    assert_equal 1, Faceoff.new.number_of_questions(2)
    assert_equal 3, Faceoff.new.number_of_questions(3)
  end

  def test_questions_addable
    contest = Faceoff.new
    contest.status = Contest::STATUS_DRAFT
    contest.user = users(:a_user)
    assert contest.questions_addable?(users(:a_user))
    assert !contest.questions_addable?(users(:another_user))

    contest.status = Contest::STATUS_APPROVAL_PENDING
    assert !contest.questions_addable?(users(:a_user))
  end

end
