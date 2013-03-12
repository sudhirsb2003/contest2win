require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :prizes, :contest_prizes, :short_listed_winners
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_friends
    num_deliveries = ActionMailer::Base.deliveries.size
    num_friends = users(:another_user).number_of_friends
    post :add_friend, {:username => users(:a_user).username}, {:user => users(:another_user) }
    assert users(:another_user).friends.include?(users(:a_user))
    assert_equal num_friends+1, users(:another_user).reload.number_of_friends
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size # check that mail was sent

    post :friends, {:username => users(:another_user).username}
    assert assigns['friends'].include?(users(:a_user))

    post :remove_friend, {:username => users(:a_user).username}, {:user => users(:another_user) }
    assert ! users(:another_user).friends.include?(users(:a_user))
    assert_equal num_friends, users(:another_user).reload.number_of_friends
  end

  def test_send_message
    num_deliveries = ActionMailer::Base.deliveries.size
    num_messages_received = users(:a_user).messages_received.count
    post :send_message, {:username => users(:a_user).username, :message => {:body => 'test'}},
        {:user => users(:another_user) }
    assert_equal num_messages_received+1, users(:a_user).messages_received.count
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size # check that mail was sent
  end

  def test_send_message_to_user_who_prefers_not_receive_alerts
    users(:a_user).preferences.create(:preference_type => UserPreference::PREFERENCE_TYPES[:no_mail_on_message])
    assert users(:a_user).has_preference?(UserPreference::PREFERENCE_TYPES[:no_mail_on_message])

    num_deliveries = ActionMailer::Base.deliveries.size
    num_messages_received = users(:a_user).messages_received.count
    post :send_message, {:username => users(:a_user).username, :message => {:body => 'test'}},
        {:user => users(:another_user) }
    assert_equal num_messages_received+1, users(:a_user).messages_received.count
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size # check that no mail was sent
  end

  def messages
    post :messages, {:username => users(:a_user).username}
    messages = assigns['messages']
    assert_response 200
  end

  def delete_message
    # try deleting someone else's  message 
    post :delete_message, {:username => users(:a_user).username, :message_id => messages.to_a[0].id},
        {:user => users(:user4) }
    assert_equal num_messages_received+1, users(:a_user).messages_received.count

    post :delete_message, {:username => users(:a_user).username, :message_id => messages.to_a[0].id},
        {:user => users(:a_user) }
    assert_equal num_messages_received, users(:a_user).messages_received.count
  end

  def test_confirm_acceptance_access_denied
    short_listed_winner = short_listed_winners(:test_for_no_tds)
    get :confirm_acceptance, {:username => users(:a_user).username, :id => short_listed_winner.id},
        {:user => users(:another_user) }
    assert_response 401
    assert_template 'shared/access_denied'
  end

  def test_confirm_acceptance_get
    short_listed_winner = short_listed_winners(:test_for_no_tds)
    get :confirm_acceptance,
        {:username => users(:a_user).username, :id => short_listed_winner.id},
        {:user => users(:a_user) }
    assert assigns['short_listed_winner']
  end

  def test_confirm_acceptance_no_tds
    short_listed_winner = short_listed_winners(:test_for_no_tds)
    dispatch = { :mobile_number => '090909890', :pin_code => '400057', :address_line_1 => '23 pari',
      :phone_number => '434343', :city => 'Mumbai', :state => 'Maharashtra', :country => 'India'
                }
    assert_equal users(:a_user).id, short_listed_winner.user.id
    post :confirm_acceptance,
        {:username => users(:a_user).username, :id => short_listed_winner.id, :dispatch => dispatch},
        {:user => users(:a_user) }
    assert assigns['dispatch']
    assert assigns['dispatch'].id
    assert assigns['dispatch'].errors.empty?
    assert_equal Dispatch::STATUSES[:pending_shipment], assigns['dispatch'].status
  end

  def test_confirm_acceptance_tds
    short_listed_winner = short_listed_winners(:test_for_tds)
    dispatch = { :mobile_number => '090909890', :pin_code => '400057', :address_line_1 => '23 pari',
      :phone_number => '434343', :city => 'Mumbai', :state => 'Maharashtra', :country => 'India'
    }
    assert_equal users(:a_user).id, short_listed_winner.user.id
    post :confirm_acceptance,
        {:username => users(:a_user).username, :id => short_listed_winner.id, :dispatch => dispatch},
        {:user => users(:a_user) }
    assert assigns['dispatch']
    assert assigns['dispatch'].id
    assert assigns['dispatch'].errors.empty?
    assert_equal Dispatch::STATUSES[:awaiting_payment], assigns['dispatch'].status
  end

end
