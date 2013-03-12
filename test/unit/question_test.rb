require File.dirname(__FILE__) + '/../test_helper'

class QuestionTest < Test::Unit::TestCase
  fixtures :users, :contests, :questions 

  def test_deletable
    assert questions(:live).deletable?(questions(:live).user), "Submitter can delete" 
    assert questions(:live).deletable?(questions(:live).contest.user), "Creator of the F/O can delete"
    assert questions(:live).deletable?(users(:a_moderator)), "a moderator can delete"
    assert ! questions(:live).deletable?(users(:user4)), "some other user cannot delete"

    question = questions(:live)
    contest = question.contest
    contest.toggle(:locked)

    assert contest.locked?
    assert ! questions(:live).deletable?(questions(:live).user), "Submitter cannot delete if contest is locked" 
    assert ! questions(:live).deletable?(contest.user), "Creator cannot delete if contest is locked" 
    assert questions(:live).deletable?(users(:a_moderator)), "a moderator can delete even when locked"
  end

  def test_editable_live
    assert ! questions(:live).editable?(questions(:live).user), "Submitter cannot edit" 
    assert ! questions(:live).editable?(questions(:live).contest.user), "Creator of the F/O cannot edit"
    assert questions(:live).editable?(users(:a_moderator)), "a moderator can edit"
    assert ! questions(:live).editable?(users(:user4)), "some other user cannot edit"
  end

  def test_editable_pending
    assert questions(:draft).editable?(questions(:draft).user), "Submitter can edit drafts"
    assert !questions(:pending).editable?(questions(:pending).user), "Submitter cannot edit if approve is pending" 
    assert ! questions(:pending).editable?(questions(:pending).contest.user), "Creator of the F/O cannot edit"
    assert questions(:pending).editable?(users(:a_moderator)), "a moderator can edit"
    assert ! questions(:pending).editable?(users(:user4)), "some other user cannot edit"
  end
  
  def test_char_limit_for_rateme
    rateme = contests(:rateme_1)
    @question3 = rateme.questions.build({:question => '123456789 123456789 123456789 123456789 123456789', :content_type => Contest::CONTENT_TYPE_TEXT})
    @question3.user_id = 2
    assert @question3.save, "other questions can be more than 40 chars"

    @question4 = rateme.questions.build({ :question => 'ESTT UORY SNAREW uuuuu uuuuu uuuuu ddddddd ddddd ddddd hhhh hhhh hhhhhhh yuy yuyuyuyuy ooo tttterrwer rwerwewerw errererrrrrrgg'})
	@question4.user_id = 2
	assert ! @question4.save , "other questions cannot be more than 100 characters"
  end

  def test_char_limit_for_twister
	  twister = contests(:twister_1)
    @question1 = twister.questions.build({:question => 'ESTT UORY SNAREW', :content_type => Contest::CONTENT_TYPE_TEXT})
    @question1.user_id = 2
	  assert @question1.save , "twister question less than 40 characters"

    @question2 = twister.questions.build({:user_id=>'2', :question => '123456789 123456789 123456789 123456789 123456789'})
    @question2.user_id = 2
    assert ! @question2.save , "twister question cannot be more than 40 characters"
  end

  def test_external_youtube_url
	  quiz = contests(:quiz_for_youtube_url)
    @question = quiz.questions.build({:question => 'test', :external_video_url => 'invalid URL', :content_type => Contest::CONTENT_TYPE_YT_VIDEO})
    assert !@question.valid?
    assert_equal true, @question.errors.invalid?(:external_video_url)
    @question2 = quiz.questions.build({:question => 'test', :external_video_url => 'http://www.youtube.com/watch?v=OrnzYF0SMvM'})
    assert_equal false, @question2.errors.invalid?(:external_video_url)
    assert_equal 'http://i.ytimg.com/vi/OrnzYF0SMvM/default.jpg', @question2.external_video_img_url
    assert_equal 'OrnzYF0SMvM', @question2.external_video_id
  end

  def test_invalid_external_youtube_url
    q = Question.new({:external_video_url => 'foo'})
    assert_equal 'error', q.external_video_id # invalid urls shouldn't crash the system!!!!!! Handle them gracefully instead.
  end

  def test_content_types
    q = Question.new(:content_type => 'Image', :image => File.new("#{RAILS_ROOT}/test/fixtures/images/spacer.gif"))
    q.save
    assert_equal Contest::CONTENT_TYPE_IMAGE, q.content_type
    q.image = nil
    q.save
    assert_equal 'Text', q.content_type
  end
end
