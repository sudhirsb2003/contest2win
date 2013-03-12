require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  fixtures :users, :contests, :old_c2w_users, :credit_transactions, :user_activation_codes

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_bad_login
    post :login, :user => {'email' => "nikhilgupte@gmail.com", 'password' => "jim277BAD"}
    assert session[:user].nil?
    assert_equal 'Email/Password not found!', flash[:notice]
  end

  def test_good_login
    post :login, :user => {'email' => "nikhilgupte@gmail.com", 'password' => "jim277"}
    assert session[:user].id == 1
    assert "Login successful", flash[:notice]
  end

  def test_change_password_too_short
    post :change_password, {:user => {:current_password => 'jim277', :password => '1', :password_confirmation => '1'}},
        {:user => users(:a_user)}
    error = assigns['tmp_user'].errors.on(:password).is_a?(String) ? assigns['tmp_user'].errors.on(:password) : assigns['tmp_user'].errors.on(:password)[0]
    assert_equal 'is too short (minimum is 5 characters)', error
  end

  def test_change_password_wrong_confirmation
    post :change_password, {:user => {:current_password => 'jim277', :password => '123456', :password_confirmation => '123456-boo'}},
        {:user => users(:a_user)}
    error = assigns['tmp_user'].errors.on(:password).is_a?(String) ? assigns['tmp_user'].errors.on(:password) : assigns['tmp_user'].errors.on(:password)[0]
    assert_equal "doesn't match confirmation", error
  end

  def test_change_password_wrong_current_password
    post :change_password, {:user => {:current_password => 'jim27', :password => '123456', :password_confirmation => '123456'}},
        {:user => users(:a_user)}
    assert_equal "is incorrect", assigns['tmp_user'].errors.on(:current_password)
  end

  def test_change_password
    post :change_password, {:user => {:current_password => 'jim277', :password => '123456', :password_confirmation => '123456'}},
        {:user => users(:a_user)}
    assert_equal User.sha1('123456'), assigns['user'].password
  end

  def test_registration
    num_deliveries = ActionMailer::Base.deliveries.size
    post :register, {:user => old_c2w_users(:jim).to_user.attributes.delete_if{|k,v| ![:username, :email,
        :gender, :date_of_birth, :address_line_1, :address_line_2, :state, :city, :country, :pin_code,
        :mobile_number, :phone_number].include?(k.to_sym)}.merge({:password_confirmation => 'jim277', :password => 'jim277'})}
    assert assigns['user'].errors.empty?
    assert assigns['user'].activation_required?
    assert assigns['user'].activation_code
    assert !session[:user]
    assert_equal 1, assigns['user'].credit_transactions(true).count
    assert_equal AppConfig.sign_up_bonus_credits, assigns['user'].prize_points
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size # check that mail was sent
  end

  def test_resend_activation_email
    user = users(:activation_pending_user)
    num_deliveries = ActionMailer::Base.deliveries.size
    post :resend_activation_email, {:email_address => user.email}
    assert_equal @response.body, 'Activation code resent to your email address'
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size # check that mail was sent

    post :resend_activation_email, {:email_address => 'nikhilgupte@gmail.com'}
    assert_equal @response.body, 'Your account has already been activated!'

    post :resend_activation_email, {:email_address => 'notfound@gmail.com'}
    assert_equal @response.body, 'Account not found!'
  end

  def test_activate
    user = users(:activation_pending_user)
    assert user.activation_code
    get :activate, {:u => user.id, :c => 'invalid'}
    assert_equal 'Invalid Activation Code', flash[:notice]

    num_deliveries = ActionMailer::Base.deliveries.size
    get :activate, {:u => user.id, :c => user.activation_code.code}
    assert_equal 'Your account has been activated!', flash[:notice]
    assert_redirected_to :controller => 'account', :action => :login
    assert user.reload.live?
    assert_equal num_deliveries+1, ActionMailer::Base.deliveries.size # check that mail was sent

    get :activate, {:u => 420, :c => 'invalid'}
    assert_equal 'Invalid Activation Code', flash[:notice]

  end

  def test_login_with_activation_pending
    user = users(:activation_pending_user)
    post :login, :user => {'email' => user.email, 'password' => "password"}
    assert_template 'account/activation_pending'
  end

  # Tests for user migrations

  # Here an old c2w account comes to the new site and does a migration and gets
  # pre-populated 
  def test_basic_account_migration_step1
    post :migrate, {:old_c2w_user_id => old_c2w_users(:jim).email, :password => old_c2w_users(:jim).password}
    assert assigns['old_c2w_user']
    assert_equal old_c2w_users(:jim).password, assigns['old_c2w_user'].password
    assert !assigns['old_c2w_user'].migrated?
    assert User.find_by_email(assigns['old_c2w_user'].email).nil? #there should be no other user with same email for this test
    assert assigns['user']
    assert_equal old_c2w_users(:jim).userid, assigns['user'].username
    assert_equal old_c2w_users(:jim).email, assigns['user'].email
    assert_equal old_c2w_users(:jim).first_name, assigns['user'].first_name
    assert_equal old_c2w_users(:jim).last_name, assigns['user'].last_name
    assert_equal old_c2w_users(:jim).date_of_birth, assigns['user'].date_of_birth
    assert_equal old_c2w_users(:jim).mobile_number, assigns['user'].mobile_number
    assert_equal old_c2w_users(:jim).contact_number, assigns['user'].phone_number
    assert_equal old_c2w_users(:jim).address, assigns['user'].address_line_1
    assert_equal old_c2w_users(:jim).city, assigns['user'].city
    assert_equal old_c2w_users(:jim).state, assigns['user'].state
    assert_equal old_c2w_users(:jim).country, assigns['user'].country
    assert_equal 'Male', assigns['user'].gender
  end

  def test_basic_account_migration_step1_failures
    old_c2w_users(:jim).update_attribute(:migrated_on, Time.now)
    post :migrate, {:old_c2w_user_id => old_c2w_users(:jim).email, :password => old_c2w_users(:jim).password}
    assert assigns['old_c2w_user'].migrated?
    assert 'This account has already been migrated!', flash[:error]

    post :migrate, {:old_c2w_user_id => old_c2w_users(:jim).email, :password => 'boo'}
    assert assigns['old_c2w_user'].errors.invalid?(:password)

    post :migrate, {:old_c2w_user_id => old_c2w_users(:jim).email}
    assert assigns['old_c2w_user'].errors.invalid?(:password)
  end

  # Here the account is actually created
  def test_basic_account_migration_step2
    post :register, {:user => old_c2w_users(:jim).to_user.attributes.delete_if{|k,v| ![:username, :email,
        :gender, :date_of_birth, :address_line_1, :address_line_2, :state, :city, :country, :pin_code,
        :mobile_number, :phone_number].include?(k.to_sym)}.merge({:password_confirmation => 'jim277', :password => 'jim277'})},
        {:old_c2w_user => old_c2w_users(:jim)}
    assert assigns['user'].errors.empty?
    user = assigns['user']
    assert !session[:user]
    assert session[:old_c2w_user].nil?
    assert old_c2w_users(:jim).migrated?
    assert_equal AppConfig.migration_bonus_credits + AppConfig.sign_up_bonus_credits + old_c2w_users(:jim).points, user.prize_points
    assert_equal AppConfig.migration_bonus_credits > 0 ? 3:2, user.credit_transactions.count
    assert_equal user.id, old_c2w_users(:jim).new_user_id
    assert_equal  old_c2w_users(:jim).date_of_registration.to_time.to_i, user.created_on.to_time.to_i
  end

  # Here the prize points are negative hence not migrated
  def test_basic_account_migration_step2_negative_points
    post :register, {:user => old_c2w_users(:janis).to_user.attributes.delete_if{|k,v| ![:username, :email,
        :gender, :date_of_birth, :address_line_1, :address_line_2, :state, :city, :country, :pin_code,
        :mobile_number, :phone_number].include?(k.to_sym)}.merge({:password_confirmation => 'janis', :password => 'janis'})},
        {:old_c2w_user => old_c2w_users(:janis)}
    assert assigns['user'].errors.empty?
    assert !session[:user]
    user = assigns['user']
    assert session[:old_c2w_user].nil?
    assert old_c2w_users(:janis).migrated?
    assert_equal AppConfig.migration_bonus_credits + AppConfig.sign_up_bonus_credits, user.prize_points
    assert_equal AppConfig.migration_bonus_credits > 0 ? 3:2, user.credit_transactions.count
    assert_equal user.id, old_c2w_users(:janis).new_user_id
    assert_equal old_c2w_users(:janis).date_of_registration.to_time, user.reload.created_on.to_time
  end

  # Here the prize points are migrated
  def test_account_migration_of_existing_user
    post :register, {:user => old_c2w_users(:jim).to_user.attributes.delete_if{|k,v| ![:username, :email,
        :gender, :date_of_birth, :address_line_1, :address_line_2, :state, :city, :country, :pin_code,
        :mobile_number, :phone_number].include?(k.to_sym)}.merge({:password_confirmation => 'janis', :password => 'janis'})}
    assert assigns['user'].errors.empty?
    assert assigns['user'].activation_required?
    assert assigns['user'].activation_code
    assert !session[:user]
    new_user_id = assigns['user'].id
    password = User.find(assigns['user'].id).password
    # above code merely sets-up the test case...

    post :migrate, {:old_c2w_user_id => old_c2w_users(:jim).email, :password => old_c2w_users(:jim).password}
    assert User.find_by_email(assigns['old_c2w_user'].email) #there should be user with same email for this test
    assert assigns['old_c2w_user'].migrated?
    assert_equal User.sha1('janis'), password
    assert_equal AppConfig.migration_bonus_credits> 0 ? 3:2, User.find_by_email(assigns['old_c2w_user'].email).credit_transactions.count
    assert_equal AppConfig.migration_bonus_credits+ AppConfig.sign_up_bonus_credits + old_c2w_users(:jim).points,
        User.find_by_email(assigns['old_c2w_user'].email).prize_points
    assert_equal new_user_id, old_c2w_users(:jim).reload.new_user_id
    assert_equal old_c2w_users(:jim).date_of_registration.to_time, User.find(new_user_id).created_on.to_time
  end

end
