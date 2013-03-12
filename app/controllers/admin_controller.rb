class AdminController < ApplicationController
  include LoginSystem
  before_filter :login_required
  before_filter(:disable, :except => [:index])

  def flush_cache
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless logged_in?(:super_admin)
    cache = MemCache.new @@memcache_options
    cache.servers = @@memcache_servers
    cache.flush_all
    flash[:notice] = "Cache Flushed!"
    redirect_to admin_path
  end

  def move_entries_to_s3
    return render(:template => 'shared/access_denied', :status => :unauthorized) if RAILS_ENV == 'production'
    message = Entry.move_all_images_to_s3(:conditions => ['image_in_s3 = ? and status = ? and content_type = ?', false, Entry::STATUS_LIVE, Contest::CONTENT_TYPE_IMAGE],
        :order => 'updated_on desc', :limit => 10)
    flash[:notice] = message
    redirect_to admin_path
  end

  def move_questions_to_s3
    return render(:template => 'shared/access_denied', :status => :unauthorized) if RAILS_ENV == 'production'
    message = Question.move_all_images_to_s3(:conditions => ['image_in_s3 = ? and status = ? and image is not null', false, Entry::STATUS_LIVE],
        :order => 'updated_on desc', :limit => 10)
    flash[:notice] = message
    redirect_to admin_path
  end

  def move_videos_to_s3
    return render(:template => 'shared/access_denied', :status => :unauthorized) if RAILS_ENV == 'production'
    message = Video.upload_to_s3(3)
    flash[:notice] = message
    redirect_to admin_path
  end

  protected

  # Only admins can do these operations
  def authorize?(user)
     user && user.moderator?
  end
end
