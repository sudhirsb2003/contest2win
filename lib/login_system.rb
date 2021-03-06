require_dependency "user"

module LoginSystem 
  
  protected
  
  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorize?(user)
     true
  end
  
  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  # 
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end
   
  # login_required filter. add 
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management. 
  # for finer access control you can overwrite
  #   
  #   def authorize?(user)
  # 
  def login_required
    
    if not protect?(action_name)
      return true  
    end

    if logged_in? and authorize?(current_user)
      return true
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied
    return false 
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    return redirect_to(account_url(:action => 'login')) unless request.xhr?
    render :template => 'account/login.rjs', :status => 401
    #render :update, :status => 401 do |page|
      #page.insert_html :bottom, "body", :partial => 'users/access_denied'
    #end  
  end  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location(uri = nil)
    uri ||= request.request_uri
    session['return-to'] = uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    unless params[:ref].blank?
      return redirect_to(params['ref'])
    end
    if session['return-to'].nil?
      redirect_to default
    else
      redirect_to session['return-to']
      session['return-to'] = nil
    end
  end

end
