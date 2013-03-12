class Referral < ActiveRecord::Base
  belongs_to :referred, :class_name => 'User'
  belongs_to :referrer, :class_name => 'User'

  before_create :set_referred_username
  after_create :make_mutual_friends

  PP_BONUS_THRESHOLD = 2000
  CREATION_BONUS_THRESHOLD = 10
  BONUS_PP = 500

  def self.credit_referral_bonus
      now = Time.now
      self.transaction do
        connection.execute <<-SQL, 'Updating Referrals'
          UPDATE referrals set pp_threshold_reached_on = '#{now.strftime('%Y-%m-%d %H:%M:%S')}'
            FROM users WHERE referred_id = users.id AND pp_threshold_reached_on is null AND users.net_pp_earned >= #{PP_BONUS_THRESHOLD};

          INSERT INTO credit_transactions (user_id, amount, description, created_on, loyalty_points) 
            SELECT referrer_id, #{BONUS_PP}, 'Referral Bonus for user - ' || referred_username || ' (Earned required PP)', now(), false FROM referrals WHERE pp_threshold_reached_on = '#{now.strftime('%Y-%m-%d %H:%M:%S')}';

          UPDATE referrals set creation_threshold_reached_on = '#{now.strftime('%Y-%m-%d %H:%M:%S')}'
            FROM users WHERE referred_id = users.id AND creation_threshold_reached_on is null
            AND (select count(*) from contests WHERE status = #{Contest::STATUS_LIVE} AND user_id = users.id) >= #{CREATION_BONUS_THRESHOLD};

          INSERT INTO credit_transactions (user_id, amount, description, created_on, loyalty_points) 
            SELECT referrer_id, #{BONUS_PP}, 'Referral Bonus for user - ' || referred_username || ' (Created required number of Contests)', now(), false FROM referrals WHERE creation_threshold_reached_on = '#{now.strftime('%Y-%m-%d %H:%M:%S')}';

        SQL
      end
  end

  private
  def set_referred_username
    self.referred_username = User.find(self.referred_id).username
  end

  def make_mutual_friends
    referred.friends << referrer
    referrer.friends << referred
  end
end
