require File.dirname(__FILE__) + '/../test_helper'
require 'polls_controller'
require 'user'
require 'question'

# Re-raise errors caught by the controller.
class PollsController; def rescue_action(e) raise e end; end

class PollsControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :prizes, :contest_prizes, :short_listed_winners

  def setup
    @controller = PollsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Check for validations...
  def test_validations
    contest = {:title => '', :tag_list => '',
      :description => 'test', :content_type => Contest::CONTENT_TYPE_TEXT, :category_id => 1 }
    post :new, {:contest => contest}, {:user => users(:a_user) }
    assert_equal "Title can't be blank", assigns['contest'].errors.full_messages[0]
    assert_equal "Tag list can't be blank", assigns['contest'].errors.full_messages[1]
    assert_equal 2, assigns['contest'].errors.size
  end

  def test_new_poll_by_a_user
    contest = {:title => 'Testing...', :tag_list => 'auto',
      :description => 'test', :content_type => Contest::CONTENT_TYPE_TEXT, :ends_on => DateTime.now + 10.days, :category_id => 1 }
    post :new, {:contest => contest}, {:user => users(:a_user) }
    assert_equal Contest::STATUS_DRAFT, assigns['contest'].status
    assert_redirected_to contest_url(assigns['contest'].url_attributes(:action => :add_question))
  end

  def test_new_poll_by_an_admin
    contest = {:title => 'Testing...', :tag_list => 'auto',
      :description => 'test', :content_type => Contest::CONTENT_TYPE_TEXT, :ends_on => DateTime.now + 10.days, :category_id => 1 }
    post :new, {:contest => contest}, {:user => users(:an_admin) }
    assert_equal Contest::STATUS_DRAFT, assigns['contest'].status
    assert_redirected_to contest_url(assigns['contest'].url_attributes(:action => :add_question))

  end

  def test_new_question_by_a_user
    question = {:question => 'question', :content_type => Contest::CONTENT_TYPE_TEXT}
    options = {}
    3.times {|i| options[i.to_s] = {:text => "opt #{i}"}}
    contest = contests(:text_poll_2)
    post :add_question, {:id => contest.id, :question => question, :options => options, :content_type => Contest::CONTENT_TYPE_TEXT},
          {:user => users(:a_user)}
    created_question = assigns['question']
    assert assigns['question']
    assert_equal Question::STATUS_DRAFT, created_question.status

    post :confirm_question, {:id => contest.id, :question_id => created_question.id, :commit => 'Done!'},
        {:user => users(:a_user)}
    assert_equal Question::STATUS_APPROVAL_PENDING, assigns['question'].status
    assert_equal Contest::STATUS_APPROVAL_PENDING, assigns['contest'].status
  end

  def test_new_question_by_an_admin
    question = {:question => 'question', :content_type => Contest::CONTENT_TYPE_TEXT}
    options = {}
    3.times {|i| options[i.to_s] = {:text => "opt #{i}"}}
    contest = contests(:text_poll_1)

    post :add_question, {:id => contest.id, :question => question, :options => options},
          {:user => users(:an_admin)}

    created_question = assigns['question']
    assert assigns['question']
    assert_equal Question::STATUS_DRAFT, created_question.status

    post :confirm_question, {:id => contest.id, :question_id => created_question.id, :commit => 'Done!'},
        {:user => users(:an_admin)}
    assert_equal Question::STATUS_APPROVAL_PENDING, assigns['question'].status
  end

  def test_permissions_on_add_question_to_poll
    question = {:question => 'question', :content_type => Contest::CONTENT_TYPE_TEXT}
    options = {}
    3.times {|i| options[i.to_s] = {:text => "opt #{i}"}}
    contest = contests(:text_poll_2) # creator is nikhil

    post :add_question, {:id => contest.id, :question => question, :options => options},
          {:user => users(:another_user)}
    assert_template 'contests/not_available'

    post :add_question, {:id => contest.id, :question => question, :options => options},
          {:user => users(:an_admin)}
    assert_response :redirect

    post :add_question, {:id => contest.id, :question => question, :options => options},
          {:user => users(:a_user)}
    assert_response :redirect
  end

  def test_winners
    assert_equal 1, contests(:text_poll_1).winners.size
    get :winners, {:id => contests(:text_poll_1).id}
    assert_response :success
    assert_template 'contests/winners'
    assert assigns['contest']
    assert assigns['winners']
    assert_equal 1, assigns['winners'].size
  end
end
