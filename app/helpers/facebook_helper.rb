module FacebookHelper
  def fb_authorized?
    !session[:facebook_id].nil?
  end

  def fb_logout_link(label, url)
    link_to_function label, "fbLogout()"
  end

  def fb_profile_pic(fb_user_id, options = {})
    options.reverse_merge!('facebook-logo' => true)
    "<fb:profile-pic #{options.collect{|k,v| "#{k}='#{v}'"}.join(' ')} uid='#{fb_user_id}'></fb:profile-pic>"
  end

#  def fb_name(fb_user_id, options = {})
#    options.reverse_merge!(:useyou => false, :linked => false)
#    "<fb:name class=\" FB_ElementReady\" #{options.collect{|k,v| "#{k}=\"#{v}\""}.join(' ')} uid=\"#{fb_user_id}\">nik</fb:profile-pic>"
#  end
#
end
