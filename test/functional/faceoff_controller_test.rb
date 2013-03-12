require File.dirname(__FILE__) + '/../test_helper'
require 'faceoffs_controller'
require 'user'
require 'question'

# Re-raise errors caught by the controller.
class FaceoffsController; def rescue_action(e) raise e end; end

class FaceoffsControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :prizes, :contest_prizes, :short_listed_winners

  def setup
    @controller = FaceoffsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Tests the best case scenario 
  def test_play_always_pick_unsorted
    faceoff = contests(:faceoff_optimization)
    3.times {|i| e = faceoff.entries.build(:title => "#{i}", :description => 'boo'); e.user_id = faceoff.user_id; e.save}
    faceoff.approve(users(:an_admin))
    assert_equal 3, faceoff.questions.count

    user = users(:a_user)
    get :play, {:id => faceoff.id }, {:user => user}
    question = assigns['question']
    contest_response = assigns['contest_response']
    #p contest_response.ranked_entries.each {|e| p "#{e.id}  #{e.points} #{e.sorted}" }
    assert_not_nil question
    assert_not_nil contest_response
    assert_equal 1, contest_response.ranked_entries.sorted(:all).size
    assert_equal 2, contest_response.ranked_entries.count
    assert_equal 1, contest_response.ranked_entries.unsorted(:all).size

    e1, e2 = question.entries.first, question.entries.last
    unsorted_entry = contest_response.ranked_entries.find_by_entry_id(contest_response.ranked_entries.find_by_entry_id(e1.id).sorted? ? e2.id : e1.id)
    sorted_entry = contest_response.ranked_entries.find_by_entry_id(contest_response.ranked_entries.find_by_entry_id(e1.id).sorted? ? e1.id : e2.id)
    a,b = sorted_entry, unsorted_entry

    assert a.sorted?
    assert !b.sorted?
    assert_equal 0, a.points
    assert_equal 0, b.points
    assert_equal 0, a.lower_bound
    assert_equal 0, b.lower_bound
    assert_equal 0, a.upper_bound
    assert_equal 1, b.upper_bound

    post :answer, {:id => faceoff.id, :question_id => question.id, :answer => {:question_option_id => question.options.find_by_entry_id(b.entry_id).id} }, {:user => user}
    b.reload
    #assert_equal 1, b.lower_bound
    #assert_equal a.points + 1, b.lower_bound
    #assert_equal 1, b.upper_bound
    assert_equal 1, b.points
    assert b.sorted?

    get :play, {:id => faceoff.id }, {:user => user}
    question = assigns['question']
    contest_response = assigns['contest_response']

    e1, e2 = question.entries.first, question.entries.last
    unsorted_entry = contest_response.ranked_entries.find_by_entry_id(contest_response.ranked_entries.find_by_entry_id(e1.id).sorted? ? e2.id : e1.id)
    sorted_entry = contest_response.ranked_entries.find_by_entry_id(contest_response.ranked_entries.find_by_entry_id(e1.id).sorted? ? e1.id : e2.id)
    c = unsorted_entry
    assert_equal 2, contest_response.ranked_entries.sorted(:all).size
    assert !c.sorted?
    assert_equal b, sorted_entry
    assert_equal 1, b.points
    assert_equal 0, c.lower_bound
    assert_equal 2, c.upper_bound

    post :answer, {:id => faceoff.id, :question_id => question.id, :answer => {:question_option_id => question.options.find_by_entry_id(unsorted_entry.entry_id).id} }, {:user => user}

    c.reload
    assert_equal 1, b.points
    #assert_equal 1, c.lower_bound
    #assert_equal 3, c.upper_bound
    assert_equal 2, c.points
    assert c.sorted?

    get :play, {:id => faceoff.id }, {:user => user}
    unsorted_entry.reload
    assert unsorted_entry.sorted?
  end

  # Tests the worst case scenario 
  def test_play_always_pick_sorted
    faceoff = contests(:faceoff_optimization)
    3.times {|i| e = faceoff.entries.build(:title => "#{i}", :description => 'boo'); e.user_id = faceoff.user_id; e.save}
    faceoff.approve(users(:an_admin))
    assert_equal 3, faceoff.questions.count

    user = users(:a_user)
    get :play, {:id => faceoff.id }, {:user => user}
    question = assigns['question']
    contest_response = assigns['contest_response']
    assert_not_nil question
    assert_not_nil contest_response
    assert_equal 2, contest_response.ranked_entries.count
    assert_equal 1, contest_response.ranked_entries.unsorted(:all).size

    e1, e2 = question.entries.first, question.entries.last
    sorted_entry = contest_response.ranked_entries.find_by_entry_id(contest_response.ranked_entries.find_by_entry_id(e1.id).sorted? ? e1.id : e2.id)
    unsorted_entry = contest_response.ranked_entries.find_by_entry_id(contest_response.ranked_entries.find_by_entry_id(e1.id).sorted? ? e2.id : e1.id)
    a, b = sorted_entry, unsorted_entry

    #assert_equal -1, sorted_entry.lower_bound
    #assert_equal 1000000, sorted_entry.upper_bound
    assert_equal 0, a.points
    assert a.sorted?
    assert !b.sorted?
    assert_equal 0, b.lower_bound
    assert_equal 1, b.upper_bound

    post :answer, {:id => faceoff.id, :question_id => question.id, :answer => {:question_option_id => question.options.find_by_entry_id(a.entry_id).id} }, {:user => user}
    b.reload
    a.reload
    assert_equal 0, b.points
    assert_equal 1, a.points

  end

end
