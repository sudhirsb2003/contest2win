require File.dirname(__FILE__) + '/../test_helper'
require 'quizzes_controller'
require 'user'
require 'question'

# Re-raise errors caught by the controller.
class QuizzesController; def rescue_action(e) raise e end; end

class QuizzesControllerTest < Test::Unit::TestCase
  fixtures :users, :contests

  def setup
    @controller = QuizzesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Check for validations...
  def test_validations
    contest = {:title => '', :tag_list => '',
      :description => 'test', :content_type => Contest::CONTENT_TYPE_TEXT, :category_id => 1}
    post :new, {:contest => contest}, {:user => users(:a_user) }
    assert_equal "Title can't be blank", assigns['contest'].errors.full_messages[0]
    assert_equal "Tag list can't be blank", assigns['contest'].errors.full_messages[1]
    assert_equal 2, assigns['contest'].errors.size
  end

  def test_new_quiz_by_a_user
    contest = {:title => 'Testing...', :tag_list => 'auto',
      :description => 'test', :content_type => Contest::CONTENT_TYPE_TEXT, :never_ends => 'true', :category_id => 1 }
    post :new, {:contest => contest}, {:user => users(:a_user) }
    assert !assigns['contest'].new_record?
    assert_equal Contest::STATUS_DRAFT, assigns['contest'].status
    assert_redirected_to contest_url(assigns['contest'].url_attributes(:action => :add_question))
  end

  def test_new_quiz_by_an_admin
    contest = {:title => 'Testing...', :tag_list => 'auto',
      :description => 'test', :content_type => Contest::CONTENT_TYPE_TEXT, :never_ends => 'true', :category_id => 1 }
    post :new, {:contest => contest}, {:user => users(:an_admin) }
    assert !assigns['contest'].new_record?
    assert_equal Contest::STATUS_DRAFT, assigns['contest'].status
    assert_redirected_to contest_url(assigns['contest'].url_attributes(:action => :add_question))
  end

  def test_new_question_by_a_user
    question = {:question => 'question', :content_type => Contest::CONTENT_TYPE_TEXT}
    options = {}
    3.times {|i| options[i.to_s] = {:text => "opt #{i}"}}
    contest = contests(:text_quiz_1)
    post :add_question, {:id => contest.id, :question => question, :options => options},
          {:user => users(:a_user)}
    assert_equal "A correct option must be specified", assigns['question'].errors.full_messages[0].strip

    post :add_question, {:id => contest.id, :question => question, :options => options, :correct_option => 1.to_s},
          {:user => users(:a_user)}

    created_question = assigns['question']
    assert assigns['question']
    assert_equal Question::STATUS_DRAFT, created_question.status

    post :confirm_question, {:id => contest.id, :question_id => created_question.id, :commit => 'Done!'},
        {:user => users(:a_user)}
    assert_equal Question::STATUS_APPROVAL_PENDING, assigns['question'].status
  end

  def test_new_question_by_an_admin
    question = {:question => 'question', :content_type => Contest::CONTENT_TYPE_TEXT}
    options = {}
    3.times {|i| options[i.to_s] = {:text => "opt #{i}"}}
    options['2'][:points] = 10
    contest = contests(:text_quiz_1)

    post :add_question, {:id => contest.id, :question => question, :options => options}, {:user => users(:an_admin)}

    created_question = assigns['question']
    assert !assigns['question'].new_record?
    assert_equal Question::STATUS_DRAFT, created_question.status

    post :confirm_question, {:id => contest.id, :question_id => created_question.id, :commit => 'Done!'},
        {:user => users(:an_admin)}
    assert_equal Question::STATUS_APPROVAL_PENDING, Question.find(created_question.id).status
  end

  def test_permissions_on_add_question_to_quiz
    question = {:question => 'question', :content_type => Contest::CONTENT_TYPE_TEXT}
    options = {}
    3.times {|i| options[i.to_s] = {:text => "opt #{i}"}}
    contest = contests(:text_quiz_2) # creator is nikhil

    post :add_question, {:id => contest.id, :question => question, :options => options, :correct_option => 1.to_s},
          {:user => users(:another_user)}
    assert_response :unauthorized

    options['2'][:points] = 10
    post :add_question, {:id => contest.id, :question => question, :options => options}, {:user => users(:an_admin)}
    assert_response :redirect

    post :add_question, {:id => contest.id, :question => question, :options => options, :correct_option => 1.to_s},
          {:user => users(:a_user)}
    assert_response :redirect
  end

  def test_admins_can_set_start_end_dates
    starts_on = Time.now + 10.days
    ends_on = Time.now + 20.days
    contest = {:title => 'Testing...', :tag_list => 'auto',
      :description => 'test', :category_id => 1,
      'ends_on(1i)' => ends_on.year.to_s, 'ends_on(2i)' => ends_on.month.to_s, 'ends_on(3i)' => ends_on.day.to_s,
      'starts_on(1i)' => starts_on.year.to_s, 'starts_on(2i)' => starts_on.month.to_s, 'starts_on(3i)' => starts_on.day.to_s
      }
    post :new, {:contest => contest}, {:user => users(:an_admin) }
    contest = assigns['contest']
    assert !contest.new_record?
    assert_equal starts_on.to_date, contest.starts_on
    assert_equal ends_on.to_date, contest.ends_on
  end

  def test_ordinary_users_cannot_set_start_end_dates
    starts_on = Time.now + 10.days
    ends_on = Time.now + 20.days
    contest = {:title => 'Testing...', :tag_list => 'auto',
      :description => 'test', :category_id => 1,
      'ends_on(1i)' => ends_on.year.to_s, 'ends_on(2i)' => ends_on.month.to_s, 'ends_on(3i)' => ends_on.day.to_s,
      'starts_on(1i)' => starts_on.year.to_s, 'starts_on(2i)' => starts_on.month.to_s, 'starts_on(3i)' => starts_on.day.to_s
      }
    post :new, {:contest => contest}, {:user => users(:a_user) }
    contest = assigns['contest']
    assert !contest.new_record?
    assert_equal Time.now.to_date, contest.starts_on
    assert contest.never_ends?
  end

end
