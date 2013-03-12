class Prize < ActiveRecord::Base

  named_scope :all, :order => 'title'
  named_scope :most_redeemed, :conditions => ["most_redeemed = ? and credits > 0 and item_type = 'Object'", true]
  named_scope :home_fav_prizes, :conditions => ["id in (select contest_prizes.prize_id from contest_prizes inner join contests on contests.id = contest_prizes.contest_id and contests.status = #{Contest::STATUS_LIVE} and contests.starts_on <= now()::date and contests.ends_on >= now()::date and (prizes.credits <= 0 or prices.credits is null)"], :order => "random()"
    
  named_scope :available, :conditions => ['not disabled'], :order => :title
  named_scope :limited, lambda { |limit|
    { :limit => limit }
  }
  named_scope :getable, :select => 'distinct prizes.*',
      :conditions => "(credits > 0) or (cp.from_date::date <= now()::date and cp.to_date >= now()::date and cp.status = #{ContestPrize::STATUS_OPEN})",
    :joins => 'left outer join contest_prizes cp on cp.prize_id = prizes.id'
  named_scope :regional, lambda { |region_id| 
      { :conditions => ['prizes.region_id = ?', region_id] }
  }


  belongs_to :region
  has_and_belongs_to_many :categories, :class_name => 'PrizeCategory', :association_foreign_key => 'category_id'
  has_many :contest_prizes, :order => :to_date
  has_many :contests, :through => :contest_prizes, :select => 'DISTINCT contests.*',
      :conditions => "contests.status = #{Contest::STATUS_LIVE} and contests.starts_on <= now()::date and contests.ends_on >= now()::date and contest_prizes.from_date <= now()::date and contest_prizes.to_date >= now()::date"

  validates_presence_of :title, :item_type, :thumbnail, :categories, :description, :region_id
  validates_size_of :title, :maximum => 100
  validates_size_of :description, :maximum => 255
  validates_size_of :special_note, :maximum => 1000

  validates_filesize_of :image, :in => 0..100.kilobytes    
  validates_filesize_of :thumbnail, :in => 1..100.kilobytes    
  validates_file_format_of :image, :thumbnail, :in => ["jpg", "gif", "png"]

  file_column :image, :web_root => "uploads/", :root_path => "public/uploads",
      :magick => {:geometry => '200x150'}, :s3 => true, :s3_auto => :move

  file_column :thumbnail, :web_root => "uploads/", :root_path => "public/uploads",
      :magick => {:geometry => '60x60'}, :s3 => true, :s3_auto => :move

  def self.find_home_fav_prizes
    sql = "SELECT * FROM prizes WHERE id in (select contest_prizes.prize_id from contest_prizes inner join contests on contests.id = contest_prizes.contest_id and contests.status = 1 and contest_prizes.status = 0 and contest_prizes.from_date <= now()::date and contest_prizes.to_date >= now()::date and (prizes.credits <= 0 or credits is null)) AND (not disabled) limit 12"
    find_by_sql(sql)
  end
  
  #def self.find_available
    #find(:all, :conditions => 'not disabled', :order => :title)
  #end

#  def self.find_having_contests(limit = 12)
#    find(:all,
#      :conditions => "id in (select cp.prize_id from contest_prizes cp inner join contests c on cp.contest_id = c.id where cp.from_date::date <= now()::date and cp.to_date >= now()::date and c.starts_on <= now()::date and c.ends_on >= now()::date and c.status = #{Contest::STATUS_LIVE})",
#      :limit => limit, :order => 'random()')
#  end

  def prize_points?
    'Credits' == item_type
  end

  def cash?
    'Cash' == item_type
  end

  def to_s
    title
  end

  def to_param
    @to_param ||= "#{id}-#{title.strip.gsub(/[^a-z0-9]+/i, '-')}"
  end

  # True if this prize is redeemeable (has <tt>credits</tt> and <tt>type</tt> isn't <tt>Credits</tt>
  def redeemable?
    credits and credits > 0 and item_type != 'Credits'
  end

  # True if this prize is redeemeable (has <tt>credits</tt> and <tt>type</tt> isn't <tt>Credits</tt>
  # and the user cann afford to redeem this prize.
  def redeemable_by_user?(user)
    redeemable? and user and user.region_id == self.region_id and user.prize_points >= credits
  end

  def needs_dd?
    tds > 0 && region.india?
  end
  alias tds_applicable? needs_dd?

  def tds
    @tds ||= (value && value >= AppConfig.min_amount_for_tds) ? (value * AppConfig.tds_percentage/100.0) : 0
  end

  def after_save
    connection.update("UPDATE contest_prizes set region_id = #{region_id} where prize_id = #{id} and region_id != #{region_id}", "Cascade changes to prize's region")
  end

  def region_editable?
    contest_prizes.count == 0    
  end
end
