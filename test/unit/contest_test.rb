require File.dirname(__FILE__) + '/../test_helper'

class ContestTest < Test::Unit::TestCase
  fixtures :users, :contests, :contest_regions, :regions

  def test_contest_approval_pending
    contest = contests(:text_quiz_1)
    assert contest.questions_addable?(contest.user), 'creator can add questions'
  end

  def test_contest_live
    contest = contests(:text_quiz_1)
    contest.status = Contest::STATUS_LIVE
    assert contest.others_can_submit_entries
    assert contest.questions_addable?(contest.user), 'creator can add questions'
    assert contest.questions_addable?(users(:another_user)), 'another user can add questions'
    contest.others_can_submit_entries = false
    assert !contest.questions_addable?(users(:another_user)), 'another user cannot add questions when others_can_submit_entries=false'
    assert contest.questions_addable?(users(:an_admin)), 'an admin can add questions even when others_can_submit_entries=false'
  end

  def test_contest_locked
    contest = contests(:text_quiz_1)
    contest.status = Contest::STATUS_LIVE
    contest.locked = true
    assert contest.others_can_submit_entries
    assert ! contest.questions_addable?(contest.user), 'creator cannot add questions'
    assert ! contest.questions_addable?(users(:another_user)), 'another user cannot add questions'
    assert ! contest.questions_addable?(users(:a_moderator)), 'a moderator cannot add questions'
    assert contest.questions_addable?(users(:an_admin)), 'an admin can add questions'
  end

  def test_never_ends
    assert ! Contest.new(:ends_on => Time.now).never_ends?
    assert Contest.new(:never_ends => 'true').never_ends?
    assert Contest.new(:ends_on => Date.parse('2020-01-01')).never_ends?
  end

  def test_loyalty_points
    region_india = regions(:India)
    assert contests(:text_quiz_1).contest_regions.find_by_region_id(region_india.id).loyalty_points_enabled?
    assert contests(:text_quiz_1).loyalty_points_applicable?(region_india.id)

    contests(:text_quiz_1).ends_on = (Time.now - 1.day).to_date
    assert contests(:text_quiz_1).contest_regions.find_by_region_id(region_india.id).loyalty_points_enabled?
    assert !contests(:text_quiz_1).loyalty_points_applicable?(region_india.id)
  end

  def test_questions_addable
    contest = Contest.new
    contest.status = Contest::STATUS_DRAFT
    contest.user = users(:a_user)
    assert contest.questions_addable?(users(:a_user))
    assert !contest.questions_addable?(users(:another_user))

    contest.status = Contest::STATUS_APPROVAL_PENDING
    assert !contest.questions_addable?(users(:a_user))
  end

end
