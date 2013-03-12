class Campaign < Contest
  # ignore me nikhil_test
  STATUS_LIVE = 10 #we override the status to filter out campaigns from the list of contests
  CAMPAIGN_TYPES = {:creation => 'C', :play => 'P'}

  named_scope :live, :conditions => "contests.status = #{STATUS_LIVE}"
  named_scope :all, :order => 'starts_on desc, ends_on asc'
  named_scope :creation, :conditions => ['campaign_type = ?', CAMPAIGN_TYPES[:creation]]
  named_scope :supporting, lambda { |contest_type| 
      { :conditions => ['campaign_contest_types.contest_type = ?', contest_type], :joins => 'inner join campaign_contest_types on contests.id = campaign_contest_types.contest_id' }
  }

  has_many :contest_types, :class_name => 'CampaignContestType', :foreign_key => 'contest_id', :dependent => :delete_all, :order => 'contest_type'
  has_many :contests, :conditions => ['contests.status = ?', Contest::STATUS_LIVE]
  has_many :play2win_contest_prizes, :through => :contests, :source => :contest_prizes
  has_many :play2win_prizes, :through => :play2win_contest_prizes, :source => :prize, :uniq => true,
      :conditions => 'contest_prizes.from_date <= now()::date and contest_prizes.to_date >= now()::date'

  validates_presence_of :campaign_type

  after_update :update_contest_attributes

  def applies_to? contest_type
    contest_types.any?{|c| c.contest_type == contest_type}
  end

  def contest_type(contest_type)
    contest_types.detect(Proc.new {CampaignContestType.new(:contest_type => contest_type)}){|c| c.contest_type == contest_type}
  end

  def self.new(options = {})
    options.reverse_merge!(:starts_on => 1.day.from_now)
    options.reverse_merge!(:ends_on => options[:starts_on] + 1.month)
    super
  end

  def top_scorers(options)
    if creation_campaign?
      options.reverse_merge!({:from => self.starts_on, :to => self.ends_on, :limit => 60})
      order = %w(contests_created plays votes).include?(options[:order]) ? options[:order] : 'contests_created'
      sql = "select user_id, count(contests.id) as contests_created, sum(contests.net_votes) as votes, sum(played) as plays
        from contests inner join users on users.id = contests.user_id
        where campaign_id = #{self.id} and users.region_id = #{options[:region_id]} and contests.status = #{Contest::STATUS_LIVE}
        and contests.created_on::date >= '#{options[:from].strftime('%Y-%m-%d')}' and contests.created_on::date <= '#{options[:to].strftime('%Y-%m-%d')}' "
      if options[:exclude_users_sql]
        sql << " and user_id not in (#{options[:exclude_users_sql]})"
      end
      sql << " group by user_id order by #{order} desc limit #{options[:limit]}"
      connection.execute(sql)
    else
      []
    end
  end

  def creation_campaign?
    CAMPAIGN_TYPES[:creation] == campaign_type
  end

  def live?
    STATUS_LIVE == status
  end

  private
  def update_contest_attributes
    if brand_id_changed?
      Contest.update_all(["brand_id = ?", brand_id], ['campaign_id = ?', id])
    end
  end

end
