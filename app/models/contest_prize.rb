class ContestPrize < ActiveRecord::Base
  belongs_to :prize
  belongs_to :region
  belongs_to :contest
  belongs_to :user, :foreign_key => 'created_by_id'
  has_many :short_listed_winners, :order => :id

  STATUS_OPEN = 0
  STATUS_CLOSED = -10

  # only for reverse auctions 
  has_many :bids
  named_scope :regional, lambda { |region_id| { :conditions => ['contest_prizes.region_id = ?', region_id] }}
  named_scope :running, :conditions => ["to_date >= now()::date and from_date <= now()::date and status = #{STATUS_OPEN}"]
  named_scope :declarable, :conditions => "to_date::date < now()::date and status = #{STATUS_OPEN} and quantity >
            (select count(*) from short_listed_winners w where w.contest_prize_id = contest_prizes.id and
            (accepted = true or (accepted is null and w.created_on >= now()::date - interval '#{AppConfig.prize_expires_after_in_days} days')))",
            :order => 'to_date desc'

  attr_protected :contest_id

  validates_numericality_of :quantity, :allow_nil => true
  validates_inclusion_of :quantity, :in => 1..99, :message => 'should be between 1 and 99'
  validates_presence_of :quantity, :region_id, :prize_id
  validates_length_of :description, :maximum => 50
  validates_date :from_date
  validates_date :to_date

  def validate
    errors.add(:from_date, "cannot be before the contest's Start date") if from_date && from_date < contest.starts_on
    errors.add(:to_date, "cannot be before the From date") if from_date && to_date && from_date > to_date
    errors.add(:to_date, "cannot be after the contest's End date") if to_date && to_date > contest.ends_on
  end

  def top_scorers(options = {})
    options.reverse_merge!(:from => self.from_date, :to => self.to_date, :region_id => region_id,
        :exclude_users_sql => "select user_id from short_listed_winners where contest_prize_id = #{self.id}")
    contest.top_scorers(options)
  end

  # These are the prizes that are left to be given out to users
  # This is +quantity+  = +prizes claimed+ - +prizes not yet expired+
  def count_prizes_left
    @count_prizes_left ||= quantity - short_listed_winners.count(:conditions => "accepted = true or (accepted is null and created_on >= now()::date - interval '#{AppConfig.prize_expires_after_in_days} days')")
  end

  def started?
    from_date.to_time <= Time.now
  end

  def ended?
    to_date.to_date < Date.today
  end

#  def self.find_declarable(status, current_page = 1, page_size = 20)
#    ContestPrize.find(:all, :order => 'to_date desc',
#        :conditions => "to_date::date < now()::date and status = #{status} and quantity >
#            (select count(*) from short_listed_winners w where w.contest_prize_id = contest_prizes.id and
#            (accepted = true or (accepted is null and w.created_on >= now()::date - interval '#{AppConfig.prize_expires_after_in_days} days')))",
#        :page => {:current => current_page, :size => page_size})
#  end

  def closed?
    STATUS_CLOSED == self.status
  end

  def deletable?
    short_listed_winners.count == 0    
  end
end
