require File.dirname(__FILE__) + '/../test_helper'
require 'twisters_controller'
#require 'user'
#require 'question'

# Re-raise errors caught by the controller.
class TwistersController; def rescue_action(e) raise e end; end

class TwistersControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :questions, :question_options, :prizes, :contest_prizes, :short_listed_winners

  def setup
    @controller = TwistersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_answer
    contest = contests(:twister_1)
    question = questions(:twister1_quesiton)
    answer = {:guess => 'test your answer' }
    post :answer, {:answer => {:guess => ' Test Your  Answer '}, :id => contest.id, :question_id => question.id}, {:user => users(:a_user) }
    assert assigns['contest_response']
    resp = assigns['contest_response']
    assert_equal 1, resp.answers_count
    assert_equal 1, resp.score
  end

  def test_old_response_is_flagged
    contest = contests(:twister_1)
    question = questions(:twister1_quesiton)
    answer = {:guess => 'test your answer' }

    post :answer, {:answer => {:guess => ' Test Your  Answer '}, :id => contest.id, :question_id => question.id}, {:user => users(:a_user) }
    resp = assigns['contest_response']
    assert !resp.old_response

    post :play_again, {:id => contest.id, :action => :play_again}, {:user => users(:a_user) }
    post :answer, {:answer => {:guess => ' Test Your  Answer '}, :id => contest.id, :question_id => question.id}, {:user => users(:a_user) }
    resp2 = assigns['contest_response']
    assert resp.reload.old_response
    assert !resp2.old_response

  end

end
