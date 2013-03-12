# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include LoginSystem
  helper :all # include all helpers, all the time
  filter_parameter_logging :password, :password_confirmation

  before_filter :get_current_user, :check_fb_session
  before_filter :check_fb_session, :except => :register

  # Gets a UUID from the session if present else
  # creates a new one and adds it to the session before returning.
  def session_uuid
    unless uuid = session[:uuid]
      uuid = UUID.create.to_s
      session[:uuid] = uuid
    end
    uuid
  end

  def disable
    return unless C2W::Config.safe_mode
    if request.xhr?
      render :update, :status => :forbidden do |page|
        page.alert("Sorry, this operation cannot be done at this time.")
      end
    else
      return render(:template => 'shared/safe_mode', :layout => 'popup')
    end
  end

  def set_current_user(user)
    session[:user_id] = (user.present? ? user.id : nil)
  end

  def current_user
    session[:user_id].present? ? User.find(session[:user_id]) : nil
  end
  helper_method :current_user

  def current_user?(user)
    logged_in? && current_user.id == (user.is_a?(User) ? user.id : user)
  end
  helper_method :current_user?

  def logged_in?(type = nil)
    current_user.present? && (type.nil? || current_user.send("#{type}?"))
  end
  helper_method :logged_in?

  def admin_only
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless logged_in?(:admin)
  end

  def fb_authorized?
    !session[:facebook_id].nil?
  end

  private
  def get_current_user
    unless logged_in?
      if cookies[:p_session_id] && p = PersistentLogin.find_by_uid(cookies[:p_session_id])
        p.user.after_login
        set_current_user(p.user)
      end
    end
  end

  def check_fb_session
    if fb_authorized? && !logged_in?
      flash.now[:notice] = '<a href="/facebook/register">Register to fully enjoy and win prizes on c2w!</a>'
    end
  end

end
