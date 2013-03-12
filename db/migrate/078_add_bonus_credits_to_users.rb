class AddBonusCreditsToUsers < ActiveRecord::Migration
  def self.up
    execute %{INSERT INTO credit_transactions (user_id , amount, description, loyalty_points, created_on) select id, 200, 'Sign-up Bonus!', true, created_on from users;}
  end

  def self.down
    execute %{delete from credit_transactions}
  end
end
