class FacebookController < ApplicationController

  before_filter :verify, :only => [:login]
  before_filter :require_fb_auth, :only => [:register, :disconnect]

  # invoked when the user logged out of facebook not using our logout mechanism
  def logged_out
    reset_session
    render :update do |page|
      flash[:notice] = 'You are no longer logged-in to Facebook'
      page.reload
    end
  end

 def login
    session['return-to'] = params[:ref] unless params[:ref].nil?
    session[:fb_access_token] = facebook_cookies['access_token']
    me = facebook_user_info
    session[:facebook_id] = me["id"]
    if user = User.find_by_fb_id(me["id"])
      user.after_login
      set_current_user(user)
      flash[:notice] = "Hi #{current_user.username}, "
      if user.valid?
        flash[:notice] << "pick your play right away and start contest2winning!"
      else
        flash[:notice] << "your profile seems incomplete. Please <a href='/account/edit_profile'>update your profile</a>."
      end
    end
    if user || params[:register].nil?
      render :update do |page|
        page.redirect_to session['return-to'].blank? ? '/' : session['return-to']
      end
    else
      render :update do |page|
        page.redirect_to facebook_path(:action => :register)
      end
    end
  end

  def register
    if request.get?
      if logged_in?
        current_user.update_attribute(:fb_id, session[:facebook_id])
        redirect_to '/'
      end
      @title = "Facebook Connect"
      me = facebook_user_info
      @user = User.new(me.slice("first_name", "last_name", "email"))
      #@user.gender = me["gender"][0..0]
    else
      @user = User.new_fb_user params[:user].merge({:fb_id => session[:facebook_id]})
      @user.fb_connect = true
      if @user.save
        @user.update_attribute(:status, User::STATUS_LIVE)
        set_current_user(@user)
        flash[:notice]  = "Welcome #{@user.username}!"
        redirect_back_or_default '/'
      end
    end
  end

  def disconnect
    if request.post?
      current_user.update_attribute(:fb_id, nil)
      session[:facebook_id] = nil
      flash[:notice] = "Your Facebook account has now been disconnected from this account"
    end
    redirect_to account_path(:action => :edit_profile)
  end

  private
  def require_fb_auth
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless fb_authorized?
  end

  def verify
    return render(:nothing => true, :status => :unauthorized) if facebook_user_info.nil?
  end

  def facebook_user_info
    if facebook_cookies && @graph = Koala::Facebook::API.new(facebook_cookies["access_token"])
      return @graph.get_object("me")
    end
  end

  def facebook_cookies
    @facebook_cookies ||= Koala::Facebook::OAuth.new(AppConfig.facebook_app_id, AppConfig.facebook_app_secret).get_user_info_from_cookie(cookies)
  end

#  def verify
#    keys = cookies.clone.keys.delete_if{|k| !k.starts_with? "#{AppConfig.facebook_api_key}_"}.sort
#    sig_prefix = "#{AppConfig.facebook_api_key}_"
#    computed_sign = Digest::MD5.hexdigest(keys.collect{|k| "#{k.gsub(Regexp.new(sig_prefix), "")}=#{cookies[k]}"}.join + AppConfig.facebook_app_secret)
#    return render(:nothing => true, :status => :unauthorized) if computed_sign != cookies[AppConfig.facebook_api_key]
#  end
end
