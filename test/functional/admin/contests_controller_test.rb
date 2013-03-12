require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/contests_controller'

# Re-raise errors caught by the controller.
class Admin::ContestsController; def rescue_action(e) raise e end; end

class Admin::ContestsControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :comments

  def setup
    @controller = Admin::ContestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_email_notification_on_comments
    num_deliveries = ActionMailer::Base.deliveries.size
    assert !users(:a_user).has_preference?(UserPreference::PREFERENCE_TYPES[:no_mail_on_comment])
    comment_count = contests(:text_quiz_1).comments.count
    post :manage_comments, {:comment_ids => {'0' => comments(:comment_on_own_contest).id, '1' => comments(:comment_on_sombodies_contest).id}, :commit => 'Approve'},
        {:user => users(:an_admin) }
    assert_equal comment_count+2, contests(:text_quiz_1).comments(true).count
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size # first comment if by contest's creator, so no email
  end

  def test_email_notification_on_comments_when_user_doesnt_want_alerts
    users(:a_user).preferences.create(:preference_type => UserPreference::PREFERENCE_TYPES[:no_mail_on_comment])
    assert users(:a_user).has_preference?(UserPreference::PREFERENCE_TYPES[:no_mail_on_comment])
    num_deliveries = ActionMailer::Base.deliveries.size
    comment_count = contests(:text_quiz_1).comments.count
    post :manage_comments, {:comment_ids => {'0' => comments(:comment_on_own_contest).id, '1' => comments(:comment_on_sombodies_contest).id}, :commit => 'Approve'},
        {:user => users(:an_admin) }
    assert_equal comment_count+2, contests(:text_quiz_1).comments(true).count
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size # first comment if by contest's creator and the other creator doesn't want alerts, so no email
  end

end
