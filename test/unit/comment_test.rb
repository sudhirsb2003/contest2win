require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :users, :contests

  def test_delete
    contest = contests(:text_quiz_1)
    comment = contest.comments.build(:message => 'test')
    comment.user_id = users(:another_user).id
    comment.save!

    assert comment.deleteable?(contest.user)
    assert comment.deleteable?(users(:an_admin))
    assert !comment.deleteable?(comment.user)
  end

  def test_delete_sticky
    contest = contests(:text_quiz_1)
    comment = contest.comments.build(:message => 'test', :sticky => true)
    comment.user_id = users(:another_user).id
    comment.save!

    assert !comment.deleteable?(contest.user)
    assert comment.deleteable?(users(:an_admin))
    assert !comment.deleteable?(comment.user)
  end

end
