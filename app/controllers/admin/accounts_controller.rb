class Admin::AccountsController < AdminController
  layout 'admin'

  active_scaffold :user do |config|
    config.columns = [:username, :email, :first_name, :last_name, :country, :level, :status, :fb_id]
    config.list.columns << [:region, :last_logged_in_on, :created_on]
    config.list.columns.exclude [:country, :level, :status, :fb_id]
    config.columns << [:net_pp_earned] unless RAILS_ENV == 'production'
    config.search.columns = [:id, :username, :email, :first_name, :last_name]
    config.actions.exclude :delete, :show, :create
    config.columns[:region].form_ui = :select
    config.columns[:level].form_ui = :select
    config.columns[:status].form_ui = :select
  end  

  protected

  # Only admins can do these operations
  def authorize?(user)
     user && user.super_admin?
  end

  def self.active_scaffold_controller_for(klass)
    return Admin::AccountsController #if klass == User
    #return "#{klass}ScaffoldController".constantize rescue super
  end

end
