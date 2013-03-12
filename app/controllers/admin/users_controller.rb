class Admin::UsersController < AdminController
  layout 'admin'

  def disabled_user_accounts
    @title = 'Disabled user accounts'
    @users = User.disabled.paginate(:page => params[:page])
  end

  def update_loyalty_points
    unless RAILS_ENV == 'production'
      User.update_loyalty_points
      flash[:notice] = 'Loyalty Points Updated'
    end
    redirect_to '/admin'
  end

  def credit_referral_bonus
    unless RAILS_ENV == 'production'
      Referral.credit_referral_bonus
      flash[:notice] = 'Referral Bonus Credited'
    end
    redirect_to '/admin'
  end

  protected

  # Only admins can do these operations
  def authorize?(user)
     user && user.super_admin?
  end
end
