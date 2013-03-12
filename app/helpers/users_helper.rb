module UsersHelper
  # Displays a link to the users profile
  def link_to_user(username, length = 50)
    link_to(truncate(username, :length => length), user_path(:username => username), :class => 'user_link')
  end

  def show_user_image(user, size = '')
    if user.facebooker?
      if size != 'thumb'
        link_to_unless_current(fb_profile_pic(user.fb_id, :facebook_logo => true, :linked => false, :size => "normal", :width => "120"), user_path(:username => user.username))
      else
        link_to_unless_current(fb_profile_pic(user.fb_id, :facebook_logo => true, :linked => false, :size => "square", :width => "60"), user_path(:username => user.username))
      end
    else
      if !url_for_file_column(user, 'picture', size).blank?
        link_to_unless_current(image_tag(url_for_file_column(user, 'picture', size), :alt => ''), user_path(:username => user.username))
      elsif 'Male' == user.gender
        link_to_unless_current(image_tag("user_without_image#{'_big' if size != 'thumb'}.gif", :alt => ''), user_path(:username => user.username))
      else  
        link_to_unless_current(image_tag("female_user_without_image#{'_big' if size != 'thumb'}.gif", :alt => ''), user_path(:username => user.username))
      end
    end
  end

end
