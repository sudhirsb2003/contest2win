#-- $Id: contest.rb 296 2007-08-23 20:44:38Z ngupte $
#++
#
# The AccountController has methods for users to manage their 
# accounts.
#
require 'c2w'
require 'uri'
require 'net/http'
require 'net/https'

class AccountController < ApplicationController
  before_filter :login_required, :except => [:login, :register, :logout, :forgot_password,  :new_password, :migrate, :forgot_old_password, :fetch_states, :activation_pending, :resend_activation_email, :activate, :transfer_from_cb]
  before_filter(:disable, :except => [:login, :logout])

  before_filter :not_for_facebookers, :only => [:change_password]

  def index() end

  def edit_profile
    @user = current_user
    if :post == request.method
        params[:user].delete(:country)
        @user.attributes = params[:user]
        @user.email.downcase!
        @user.self_update = true
        if @user.save
          flash.now[:notice] = 'Profile updated!'
        end  
    end
  render :layout => 'users'
  end

  def forgot_password
    if :post == request.method
        if user = User.find_by_email(params[:email_address].downcase)
          UserMailer.deliver_password_regeneration_instructions(self, user, LoginToken.generate(user).token)
          flash.now[:notice] = 'Instructions for regenerating your password have been sent to your email address.'
        else
          flash.now[:notice] = 'No user by that email address was found!'
        end  
    end
  end

  # Allows generation of password without prompting for the old password. Instead it uses a <tt>LoginToken</tt>.
  def new_password
    if token = LoginToken.find_by_token(params[:token])
      @user = token.user
      if request.post?
        @tmp_user = User.new(params[:user])
        @tmp_user.validate_attributes(:only => [:password, :password_confirmation])
        if @tmp_user.errors.empty?
          User.transaction do
            @user.change_password(params[:user][:password])
            token.destroy
            @user.reset_login_attempts
          end  
          flash[:notice] = 'Password changed!'
          return redirect_to(account_url(:action => :login))
        end
      end # request.post?
    else
      flash[:notice] = 'Sorry, this password regeneration request is no longer valid. Please create a new request.'
      return redirect_to(account_url(:action => :forgot_password))
    end
  end

  def change_password
    if :post == request.method
        if @tmp_user = User.find_by_id_and_password(current_user.id, User.sha1(params[:user][:current_password]))
          user = User.new(params[:user])
          user.valid?
          unless user.errors.invalid?(:password) || user.errors.invalid?(:password_confirmation)
            @tmp_user.change_password(params[:user][:password])
            flash.now[:notice] = 'Password changed!'
            set_current_user(@tmp_user)
          else
            errors = user.errors.on(:password)
            if errors.is_a?(Array)
              errors.each {|e| @tmp_user.errors.add(:password, e)}
            else
              @tmp_user.errors.add(:password, errors)
            end  
          end
        else
          @tmp_user = User.new
          @tmp_user.errors.add('current_password', 'is incorrect')
        end
    end
    @user = current_user
    render :layout => 'users'
  end

  def logout
    reset_session
    if cookies[:p_session_id] && p = PersistentLogin.find_by_uid(cookies[:p_session_id])
      p.destroy
    end
    cookies.delete :p_session_id
    flash[:notice] = 'You have successfully logged-out'
    redirect_to '/'
  end

  def register
    if fb_authorized?
      return redirect_to facebook_path(:action => :register)
    end
    if (params[:referred_by])
      @referred_by = User.find_by_username(params[:referred_by]) rescue nil
    end
    if request.post?
      @user = User.new(params[:user])
      @user.username = params[:user][:username]
      @user.self_update = true
      begin
        User.transaction do
          @user.save!
          if @referred_by
            @referred_by.referrals.create!(:referred_id => @user.id)
          end
          @user.preferences.create(:preference_type => UserPreference::PREFERENCE_TYPES[:no_newsletter]) unless '1' == params[:subscribe_to_newsletter]
          flash[:notice]  = "Welcome #{@user.username}!"
        end
        UserMailer.deliver_activation_mail(self, @user)
        return render(:template => 'account/activation_pending')
      rescue
        # do nothing... it'll fall back to the view to show fields tha failed validation
      end
    else
      @user = User.new(:country => request.location.country)
    end
  end

  def resend_activation_email
    if user = User.find_by_email(params[:email_address])
      if user.activation_required?
        user.set_activtion_code
        UserMailer.deliver_activation_mail(self, user)
        render :text => 'Activation code resent to your email address'
      else
        render :text => 'Your account has already been activated!'
      end
    else
      render :text => 'Account not found!'
    end
    #return render :template => 'account/activation_pending'
  end

  def activate
    if (user = User.find(params[:u]) rescue false)
      if user.activate(params[:c])
        UserMailer.deliver_welcome_mail(self, user)
        flash[:notice] = 'Your account has been activated!'
        return redirect_to(:action => :login)
      end
    end
    flash.now[:notice] = "Invalid Activation Code"
  end

  def login
    case request.method
      when :post
        begin
          captcha_failed = nil
          if ((@user = User.find_by_email(params[:user][:email])) && @user.requires_captcha?) || params[:recaptcha_challenge_field]
            unless verify_recaptcha
              flash.now[:notice] = 'Captcha verification failed.'
              captcha_failed = true
            end
          end
          unless captcha_failed
          user = User.login(params[:user][:email], params[:user][:password])
          set_current_user(user)
          flash.now[:notice] = "Hi #{current_user.username}, "
          if user.valid?
            flash.now[:notice] << "pick your play right away and start contest2winning!"
          else
            flash.now[:notice] << "your profile seems incomplete. Please <a href='/account/edit_profile'>update your profile</a>."
          end  
          if fb_authorized?
            user.update_attribute(:fb_id, session[:facebook_id])
          end
          redirect_back_or_default '/'
          if params[:persist]
            p = PersistentLogin.create(:user => user)
            cookies[:p_session_id] = {:value => p.uid, :expires => Time.now + 10.years}
          end
          end
        rescue C2W::ActivationRequired => error  
          flash.now[:notice] = error.to_s
          return render(:template => 'account/activation_pending')
        rescue C2W::Authentication => error  
          @user = User.find_by_email(params[:user][:email])
          flash.now[:notice] = error.to_s
        end
      when :get
        store_location(params[:return_url]) if params[:return_url].present?
        if logged_in?
          redirect_back_or_default '/'
        else
          @user = User.new
        end
    end
  end

  def preferences
    @user = current_user
    if request.post?
      @user.preferences.delete_all
      params[:preferences].each{|p| @user.preferences.create(:preference_type => p)} if params[:preferences]
      flash.now[:notice] = 'Preferences Updated!'
    end
    @preferences = current_user.preferences.collect(&:preference_type)
    render :layout => 'users'
  end

  def fetch_states
    @user = User.new :country => params[:country]
    render :partial => 'states.html.erb'
  end

  private
  def not_for_facebookers
    return render(:template => 'shared/access_denied', :status => :unauthorized) if current_user.facebooker?
  end
end
