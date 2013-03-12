require 'digest/sha1'
require 'c2w'

class User < ActiveRecord::Base
  include Auditable::Acts::Audited
  acts_as_auditable

  # constants 
  LEVEL_SUPER_ADMIN = 1000
  LEVEL_ADMIN = 500
  LEVEL_MODERATOR = 100
  LEVEL_CRM = 50
  LEVEL_USER = 0

  STATUS_LIVE = 1
  STATUS_ACTIVATION_PENDING = -10
  STATUS_DISABLED = -1

  MINIMUM_CONTESTS_FOR_ADSENSE = 10

  named_scope :disabled, :conditions => ['status = ?', STATUS_DISABLED], :order => :id
  named_scope :top_contest_creators,
      :select => 'users.id, users.username, users.picture, users.gender, users.picture_in_s3, sum(contests.net_votes) as total_score, count(distinct contests.id) as num_contests, fb_id',
      :joins => 'inner join contests on contests.user_id = users.id',
      :group => 'users.id, users.username, users.picture, users.gender, users.picture_in_s3, fb_id', :order => 'total_score desc',
      :conditions => ['users.level <= ? and contests.status = ?', LEVEL_MODERATOR, Contest::STATUS_LIVE]


  validates_presence_of :email, :username, :password
  validates_size_of :username, :password, :within => 5..15, :on => :create, :allow_blank => true
  validates_format_of :email, :with => %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i, :allow_blank => true
  validates_format_of :username, :with => /^\w+$/i, :message => "can only contain letters and numbers.", :allow_blank => true
  validates_confirmation_of :password, :unless => Proc.new {|u| u.facebooker?}
  validates_uniqueness_of :username, :email, :case_sensitive => false
  validates_acceptance_of :eula, :on => :create, :unless => Proc.new {|u| u.facebooker?}
  validates_filesize_of :picture, :in => 0..600.kilobytes    
  validates_file_format_of :picture, :in => ["jpg", "gif", "png"]

  validates_date :date_of_birth, :if => Proc.new { |u| u.self_update == true }
  validates_presence_of :gender, :message => 'should be selected'
  validates_presence_of :mobile_number, :city, :state, :address_line_1, :if => Proc.new { |u| u.self_update == true }
  validates_presence_of :country, :if => Proc.new { |u| u.self_update == true || u.fb_connect == true }
  validates_presence_of :first_name, :last_name, :pin_code, :phone_number, :on => :update, :if => Proc.new { |u| u.self_update == true }

  # associations 
  has_many :contests_created, :class_name => 'Contest', :order => 'contests.id desc'
  has_many :votes, :through => :contests_created
  has_many :entries, :order => 'entries.id desc'
  has_many :questions, :order => 'questions.id desc'
  has_one :activation_code, :dependent => :delete, :class_name => 'UserActivationCode'

  has_many :responses, :order => 'updated_on desc'

  has_many :answers, :through  => :responses
  has_many :messages_received, :class_name => 'Message', :foreign_key => :receiver_id, :order => 'messages.id desc'
  has_many :friendships, :dependent => :destroy
  has_many :friends, :through => :friendships, :class_name => 'User'
  has_many :favourites, :dependent => :destroy
  has_many :favourite_contests, :through => :favourites, :class_name => 'Contest', :source => :contest, :dependent => :destroy
  has_many :ignored_users, :dependent => :destroy
  has_many :ignored, :through => :ignored_users, :source => :ignored_user, :dependent => :destroy, :class_name => 'User'
  has_many :short_listed_winnings, :order => 'id desc', :class_name => 'ShortListedWinner' do
    def pending(*args)
      with_scope(:find => { :conditions => "accepted is null and created_on >= now()::date - interval '#{AppConfig.prize_expires_after_in_days} days'"} ) do
        find(*args)
      end
    end
    def won(*args)
      with_scope(:find => { :conditions => "accepted is true"} ) do
        find(*args)
      end
    end
  end
  has_many :credit_transactions, :order => 'id' do
    def in_month(date, *args)
      with_scope(:find => { :conditions => ['created_on >= ? and created_on < ?', date.beginning_of_month, date.next_month.beginning_of_month] } ) do
        find(*args)
      end
    end
  end
  belongs_to :region
  has_many :preferences, :class_name => 'UserPreference', :dependent => :delete_all
  has_many :referrals, :class_name => 'Referral', :foreign_key => :referrer_id, :order => 'created_on DESC'

  define_index do
    indexes :username
    indexes [first_name, last_name, username], :as => :name
    set_property :field_weights => {"name" => 100}
  end

  after_save :fix_dependant_username

  # plugins 
  file_column :picture, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :s3_auto => :move, :magick => {
    :geometry => "120x120>",
    :versions => {
          :thumb => {:geometry => "60x60>"}
    }
  }

  attr_protected :level, :status, :region_id, :username, :login_attempts, :net_pp_earned, :last_pp_earned

  attr_accessor :current_password, :self_update, :fb_connect

  def self.login(email, pass)
    if user = authenticate(email, pass)
      if user.live?
        user.after_login
        return user
      elsif user.activation_required?
        raise C2W::ActivationRequired, "Your account has not yet been activated!"
      else
        raise C2W::Authentication, "Your account has been disabled!"
      end  
    else
      User.update_all('login_attempts = coalesce(login_attempts, 0) + 1', ['lower(email) = ?', email.downcase])
      raise C2W::Authentication, "Email/Password not found!"
    end  
  end

  def change_password(pass)
    update_attribute "password", self.class.sha1(pass)
  end

  def is_ordinary?
    LEVEL_USER == level
  end

  def super_admin?
    LEVEL_SUPER_ADMIN == level
  end

  def admin?
    LEVEL_ADMIN <= level
  end

  def moderator?
    LEVEL_MODERATOR <= level
  end

  def crm?
    LEVEL_CRM <= level
  end

  # The <tt>level</tt> in words.
  def role
    case level
    when LEVEL_SUPER_ADMIN then 'Super Admin'
    when LEVEL_ADMIN then 'Admin'
    when LEVEL_MODERATOR then 'Moderator'
    when LEVEL_CRM then 'CRM'
    else 'User'
    end
  end
    
  def live?
    STATUS_LIVE == status
  end

  def activation_pending?
    STATUS_ACTIVATION_PENDING == status
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def points
    @points ||= answers.sum(:points) || 0
  end

  # Gets the top scorers. Only id, username, picture, gender and the total_score are populated in the user instance.
  #  * <tt>:from</tt> Only answers after this date/time will be included Default 7 days ago
  #  * <tt>:limit</tt> Default nil
  #  * <tt>:page</tt> Default nil
  def self.top_scorers(options = {})
    options.reverse_merge!({:from => (7.days.ago)})
    User.find(:all, :joins => 'inner join responses on responses.user_id = users.id inner join answers on answers.response_id = responses.id',
        :select => 'users.id, users.username, users.picture, users.gender, sum(answers.points) as total_score',
        :group => 'users.id, users.username, users.picture, users.gender', :order => 'total_score desc',
        :limit => (options[:limit] if options[:limit]),
        :page => (options[:page] if options[:page]),
        :conditions => ['answers.created_on >= ?', options[:from]])
  end

  # Gets the top contest creators based on the votes.
  def self.top_contest_creators_count(from)
    Contest.count(:user_id, :distinct => true, :joins => 'inner join users on users.id = contests.user_id',
        :conditions => ['contests.status = ? and contests.created_on >= ? and users.level <= ?', Contest::STATUS_LIVE, from, LEVEL_MODERATOR])
  end

  def self.sha1(pass)
    Digest::SHA1.hexdigest(pass)
  end
    
  # Gets the latest <tt>accepted</tt> <tt>ShortListedWinner</tt> instance with this user's user_id
  def latest_win
    short_listed_winnings.find(:first, :conditions => 'accepted = true')
  end

  def creativity
    @creativity ||= (votes.sum(:points) || 0)
  end

  # Updates loyalty points for users. Prize points only include correct answers.
  # This function can be safely called multiple times since is only includes
  # those answers which weren't included before.
  def self.update_loyalty_points
    if C2W::Config.safe_mode
      return "Cannot update during safe_mode"
    end

    this_run_time = Time.now
    self.transaction do
      last_run_time = begin
        if lplog = LoyaltyPointsLog.last
          lplog.ran_on
        else
          Time.now.beginning_of_day - 1.day + 1.minute # historically, scheduler was run at 00:01 everyday hence this is a safe bet
        end
      end
#      connection.execute <<-SQL, 'Updating Prize Points for users'
#          UPDATE users set net_pp_earned = net_pp_earned + pp.points, last_pp_earned = pp.points, pp_calculated_at = now()
#          FROM (SELECT user_id, sum(loyalty_points) as points FROM ANSWERS 
#            WHERE created_on > '#{last_run_time.strftime('%Y-%m-%d %H:%M:%S')}' and created_on <= '#{this_run_time.strftime('%Y-%m-%d %H:%M:%S')}'
#            AND loyalty_points > 0 and user_id is not null GROUP BY user_id) as pp
#          WHERE pp.user_id = users.id
#      SQL
      connection.execute <<-SQL, 'Updating Prize Points for users'
        INSERT INTO credit_transactions (user_id, amount, description, loyalty_points, created_on)
        (SELECT user_id, sum(loyalty_points) as points, 'Prize Points for Correct Answers', true, now() FROM ANSWERS 
        WHERE created_on > '#{last_run_time.strftime('%Y-%m-%d %H:%M:%S')}' and created_on <= '#{this_run_time.strftime('%Y-%m-%d %H:%M:%S')}'
        AND loyalty_points > 0 and user_id is not null GROUP BY user_id)
      SQL
      LoyaltyPointsLog.create!(:ran_on => this_run_time)
    end
  end

  def prize_points
    net_pp_earned + credit_transactions.sum(:amount)
  end
  #alias prize_points net_credits 

  # Created a Debit transaction corresponding to the purchase of the prize. 
  def redeem(prize)
    credit_transactions.create!(:amount => -prize.credits, :description => "Redeemed #{prize.title}")
  end

  # Creates a transaction based on points migration from the old system
  def create_points_migration_transaction(points)
    if points >= 0
      credit_transactions.create!(:amount => points, :description => 'Transferred points from old system')
    else
      credit_transactions.create!(:amount => 0,
          :description => "Skipped migration of #{points} points from old system")
    end
    credit_transactions.create!(:amount => AppConfig.migration_bonus_credits, :description => 'Migration Bonus!') if AppConfig.migration_bonus_credits > 0
  end

  def before_create
    write_attribute("password", self.class.sha1(password))
    self.status = STATUS_ACTIVATION_PENDING
  end

  def set_activtion_code
    create_activation_code(:code => LoginToken.random_token(8)) if activation_code.nil?
  end

  def before_save
    self.email.downcase!
    if new_region = Region.find_by_name(country)
      self.region_id = new_region.id
    else
      self.region_id = Region::DEFAULT_ID
    end
  end

  # For each <tt>user</tt> a corresponding <tt>credit_transaction</tt> with <tt>loyalty_points</tt> as true
  # *must* exist else <tt>loyalty_points</tt> calculation for that user will *fail*.
  def after_create
    credit_transactions.create!(:description => 'Sign Up Bonus!', :amount => AppConfig.sign_up_bonus_credits, :loyalty_points => false)
    set_activtion_code
  end

  def location
    @location ||= [address_line_1, address_line_2, city, state, country].join(', ')
  end

  def to_xml(options = {})  
    super(options.merge({:methods => [:prize_points], :skip_types => true,
        :only => [:username, :email, :first_name, :last_name, :id, :gender, :date_of_birth,
          :address_line_1, :address_line_2, :city, :pin_code, :state, :phone_number, :mobile_number, :country]})) do |xml|
      prepend = "?#{updated_on.to_i}"
      if picture
        if picture_in_s3?
          xml.thumbnail "#{FileColumn::S3FileColumnExtension::Config.s3_distribution_url}/#{picture_web_path('thumb')}"
          xml.picture "#{FileColumn::S3FileColumnExtension::Config.s3_distribution_url}/#{picture_web_path}"
        else
          xml.thumbnail "http://#{options[:base_url]}/#{picture_web_path('thumb')}#{prepend}"
          xml.picture "http://#{options[:base_url]}/#{picture_web_path}#{prepend}"
        end
      end  
    end
  end

  def has_preference?(preference_type)
    preferences.find_by_preference_type(preference_type) != nil
  end

  def activation_required?
    status == STATUS_ACTIVATION_PENDING
  end

  def activate(code)
    if activation_required? && activation_code && activation_code.code == code
      activation_code.destroy
      update_attribute(:status, STATUS_LIVE)
      return true
    else
      return false
    end
  end

  def self.upload_to_s3
    move_all_pictures_to_s3(:conditions => ['picture is not null and picture_in_s3 = ? and status = ?', false, STATUS_LIVE], :limit => 1000)
  end

  def requires_captcha?
    self.login_attempts != nil && self.login_attempts >= 3
  end

  def reset_login_attempts
    update_attribute :login_attempts, 0
  end

  def self.find_by_username(string)
    User.find(:first, :conditions => ['lower(username) = ?', string.downcase])
  end

  def credit_account(amount, description, loyalty_points = false)
    credit_transactions.create!(:amount => amount, :description => description, :loyalty_points => loyalty_points)
  end

  def debit_account(amount, description)
    credit_transactions.create!(:amount => -amount, :description => description)
  end

  def name
    full_name.blank? ? self.username : full_name
  end

  def status_text
    case status
    when STATUS_LIVE then 'live'
    when STATUS_ACTIVATION_PENDING then 'activation pending'
    else 'disabled'
    end
  end

  def profile_url
    "http://c2w.com/users/#{username}"
  end

  def self.new_fb_user(params) 
    user = new params
    user.username = params[:username]
    user.status = STATUS_LIVE
    user.password = SecureRandom.hex(4)
    user
  end

  def facebooker?
    !fb_id.nil?
  end

  def can_have_ad_account?
    contests_created.online.count >= MINIMUM_CONTESTS_FOR_ADSENSE
  end

  def after_login
    credit_daily_login_bonus!
    self.last_logged_in_on = Time.now()
    self.login_attempts = 0
    save
  end

  private

  def credit_daily_login_bonus!
    unless credit_transactions.exists?(["description = ? and loyalty_points = ? and created_on > ?", 'Daily Login Bonus', true, 1.day.ago])
      credit_account(AppConfig.daily_login_bonus_credits, "Daily Login Bonus", true)
    end
  end

  def self.authenticate(email, pass)
    find(:first, :conditions => ["email = ? AND password = ?", email.downcase, sha1(pass)])
  end  

  def fix_dependant_username
    if username_changed?
      Contest.update_all(['username = ?', username], ['user_id = ?', id])
      Question.update_all(['username = ?', username], ['user_id = ?', id])
      Entry.update_all(['username = ?', username], ['user_id = ?', id])
      Comment.update_all(['username = ?', username], ['user_id = ?', id])
    end
  end

end
