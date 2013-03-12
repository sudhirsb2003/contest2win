require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users, :user_activation_codes

  # Replace this with your real tests.
  def test_registration
    # invalid user
    @user = User.new({:password => 'password', :password_confirmation => 'password',
        :email => 'ngupte!contests2win.com', :eula => '1', :gender => 'Male', :city => 'Mumbai', :state => 'Maharashtra',
        :address_line_1 => '23 parineeta'})
    @user.username = 'testuser1'
    assert !(@user.save)

    # valid user
    @user = User.new({:password => 'password', :password_confirmation => 'password',
        :email => 'ngupte@contests2win.com', :eula => '1', :gender => 'Male', :city => 'Mumbai', :state => 'Maharashtra',
        :address_line_1 => '23 parineeta',
        :mobile_number => '1234', :date_of_birth => '1976-07-27'})
    @user.username = 'testuser'
    assert @user.save!
    assert @user.activation_required?
    assert @user.activation_code
    assert_equal 1, @user.credit_transactions.count
    assert true, @user.credit_transactions.first.loyalty_points
    assert_raises(C2W::ActivationRequired) { User.login("ngupte@contests2win.com", "password") }
  end

  def test_authenticate  
    assert ! User.authenticate("nikhilgupte@gmail.com", "poppp")
    assert User.authenticate("nikhilgupte@gmail.com", "jim277")
  end

  def test_duplicate_username  
    @user = User.new({:username => 'nikhil', :password => 'password', :password_confirmation => 'password',
        :email => 'ngupte@contestswin.com', :eula => '1', :gender => 'Male',
        :mobile_number => '1234', :date_of_birth => '1976-07-27'})
    assert ! @user.save
  end

  def test_duplicate_email  
    @user = User.new({:username => 'nikhil123', :password => 'password', :password_confirmation => 'password',
        :email => 'nikhilgupte@gmail.com', :eula => '1', :gender => 'Male',
        :mobile_number => '1234', :date_of_birth => '1976-07-27'})
    assert ! @user.save
  end

  def test_activate
    user = users(:activation_pending_user)
    code = user.activation_code.code
    assert !user.activate('invalid')
    assert user.activate(code)
    assert user.reload.activation_code.nil?
    assert !user.activate(code), "Cannot activate an activate account"
  end

  def test_requires_captcha?
    assert !User.find_by_email('nikhilgupte@gmail.com').requires_captcha?

    3.times {User.login('nikhilgupte@gmail.com', 'invalid') rescue nil}
    assert User.find_by_email('nikhilgupte@gmail.com').reload.requires_captcha?

    User.login('nikhilgupte@gmail.com', 'jim277')
    assert !User.find_by_email('nikhilgupte@gmail.com').requires_captcha?
  end

  def test_name
    u = User.new; u.username = 'username'
    assert_equal 'username', u.name
    u = User.new(:first_name => 'full', :last_name => 'name'); u.username = 'username'
    assert_equal 'full name', User.new(:username => 'username', :first_name => 'full', :last_name => 'name').name
  end
end
