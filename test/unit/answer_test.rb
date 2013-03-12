require File.dirname(__FILE__) + '/../test_helper'

class AnswerTest < Test::Unit::TestCase
  fixtures :users, :contests, :questions, :question_options #, :prizes, :contest_prizes

  # When a poll (which hasn't ended) is answered, the selected option's click is incremented
  def test_answer_to_poll
    contest = contests(:text_poll_1)
    response = contest.responses.create(:user_id => 1)
    question = contest.questions.first
    assert_equal 0, question.options(true).first.clicks
    assert_equal 0, question.answers_count
    answer = response.answers.create({:question_id => question.id, :question_option_id => question.options.first.id})
    assert_equal 1, question.options(true).first.clicks
    assert_equal 1, question.reload.answers_count
  end

  # When a poll (which has ended) is answered, the selected option's click is not incremented
  def test_answer_to_ended_poll
    contest = contests(:text_poll_1)
    contest.update_attribute(:ends_on, Time.now - 2.days)
    response = contest.responses.create(:user_id => 1)
    question = contest.questions.first
    assert_equal 0, question.options(true).first.clicks
    assert_equal 0, question.answers_count
    answer = response.answers.create({:question_id => question.id, :question_option_id => question.options.first.id})
    assert_equal 0, question.options(true).first.clicks
    assert_equal 0, question.reload.answers_count
  end

  # When a quiz is answered, the selected option's click is not incremented
  def test_answer_to_quiz
    contest = contests(:text_quiz_1)
    response = contest.responses.create(:user_id => 1)
    question = contest.questions.first
    assert_equal 0, question.options(true).first.clicks
    assert_equal 0, question.answers_count
    answer = response.answers.create({:question_id => question.id, :question_option_id => question.options.first.id})
    assert_equal 0, question.options(true).first.clicks
    assert_equal 0, question.reload.answers_count
  end

end
