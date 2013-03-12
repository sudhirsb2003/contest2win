class Admin::PrizeCategoriesController < AdminController
  active_scaffold :prize_category
  layout 'admin'

  def index
  end

  protected

  # Only admins can do these operations
  def authorize?(user)
     user && user.admin?
  end
end
