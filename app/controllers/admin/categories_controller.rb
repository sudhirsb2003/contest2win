class Admin::CategoriesController < AdminController
  active_scaffold :category do |config|
    config.columns.exclude :contests
    config.create.columns.exclude :slug
    config.actions.exclude :nested
    config.columns.exclude :regions
  end  
  cache_sweeper :categories_sweeper, :only => [ :destroy, :update, :create ]
  layout 'admin'

  def index
  end

  protected

  # Only admins can do these operations
  def authorize?(user)
     user && user.admin?
  end
end
