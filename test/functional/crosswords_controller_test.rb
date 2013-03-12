require File.dirname(__FILE__) + '/../test_helper'
require 'crosswords_controller'

# Re-raise errors caught by the controller.
class CrosswordsController; def rescue_action(e) raise e end; end

class CrosswordsControllerTest < Test::Unit::TestCase
  fixtures :users, :contests

  def setup
    @controller = CrosswordsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_basic
    contest = {:tag_list => 'test', :description => 'test', :category_id => 1, :title => 'Test Crossword', :never_ends => 'true'}
    post :new, {:contest => contest}, {:user => users(:a_user) }
    contest = assigns['contest']
    assert !contest.new_record?

    get :add_questions, {:id => contest.id}, {:user => users(:a_user)}
    assert_equal 10, assigns['questions'].size
    questions = {}
    %w(astonished extravagant DIAMOND cultivate fengshui piccadilly NICOTINE infant FEW sliver SPONTANEOUS negro HUMOROUS DEN alexander TRENDY PRACTICAL confidence compatriot luxorious PIOUS catastrophe mandatory lamp mist FLAMBOUYANT excavate lid pin cat).each_with_index {|a,i| questions[i] = {:answer => a, :question => 'test question'} }
    post :add_questions, {:id => contest.id, :questions => questions}, {:user => users(:a_user)}
    assert assigns['contest']
    contest = assigns['contest'].reload
    assert_equal 30, contest.all_questions(true).size
    p contest.clues.size
    assert_equal 29, contest.clues.size
    assert_redirected_to contest_url(assigns['contest'].url_attributes(:action => :preview))

    assert_equal Contest::STATUS_DRAFT, contest.status

    get :preview, {:id => contest.id}, {:user => users(:a_user)}
    assert_response 200
  end

end
