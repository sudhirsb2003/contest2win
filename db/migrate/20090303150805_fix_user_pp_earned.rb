class FixUserPpEarned < ActiveRecord::Migration
  def self.up
    execute %{
      update credit_transactions set description = 'Sign-up Bonus!' where description = 'Sign Up Bonus!';
      update credit_transactions set loyalty_points = false where description = 'Sign-up Bonus!';
      update users set net_pp_earned = COALESCE((select sum(amount) from credit_transactions where loyalty_points = true and user_id = users.id), 0);
    }
  end

  def self.down
  end
end
