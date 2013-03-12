#-- $Id: contest.rb 2823 2009-01-09 13:55:32Z ngupte $
#++
#
# A Contest can be of the following types:
# * Quiz
# * Hangman
# 
# The relationsip is modeled as STI, where all the records
# are persisted as contests.
# 
class Contest < ActiveRecord::Base
  include Auditable::Acts::Audited
  include ContestsHelper
  attr_protected :user_id, :status, :featured, :loyalty_points_enabled, :created_on, :updated_on, :slug,
      :played, :favourited, :net_votes, :stats_updated_on, :version_number
  attr_accessor :never_ends

  # constants 
  CONTENT_TYPE_VIDEO = 'Video'
  CONTENT_TYPE_IMAGE = 'Image'
  CONTENT_TYPE_TEXT = 'Text'
  CONTENT_TYPE_YT_VIDEO = 'YTVideo'

  STATUS_LIVE = 1
  STATUS_DRAFT = -1
  STATUS_APPROVAL_PENDING = 0
  STATUS_DEACTIVATED = -10
  STATUS_DELETED = -1000
  STATUS_PURGED = -10000 # means the cotests coul'nt be deleted, but all it's contents have been deleted

  DEFAULT_STATUS = STATUS_DRAFT

  acts_as_auditable
  # associations
  belongs_to :user
  belongs_to :skin # The flash UI to play this contest
  belongs_to :brand
  has_and_belongs_to_many :categories
  belongs_to :campaign

  has_many :responses, :dependent => :delete_all do
    def valid(*args)
      with_scope(:find => { :conditions => 'user_id is not null and answers_count > 0'} ) do
        find(*args)
      end
    end
  end
  has_many :votes, :foreign_key => 'voteable_id', :dependent => :delete_all
  has_many :favourites, :dependent => :delete_all
  has_many :all_comments, :class_name => 'Comment', :foreign_key => 'commentable_id', :dependent => :delete_all
  has_many :comments, :foreign_key => 'commentable_id', :order => 'comments.sticky desc, comments.id desc',
      :conditions => "comments.status = #{Question::STATUS_LIVE}"

  has_many :all_questions, :class_name => 'Question', :dependent => :destroy, :conditions => "questions.status != #{STATUS_DELETED}"
  has_many :questions, :order => 'questions.id asc', :conditions => "questions.status = #{Question::STATUS_LIVE}" do
    def latest
      find(:first, :order => 'questions.id desc')
    end
  end    
  has_many :contest_prizes, :class_name => 'ContestPrize', :dependent => :delete_all, :order => 'from_date, to_date, quantity'
  has_many :prizes, :through => :contest_prizes

  has_many :short_listed_winners, :through => :contest_prizes, :source => :short_listed_winners,
      :order => 'short_listed_winners.id desc', :dependent => :destroy

  has_many :winners, :through => :contest_prizes, :source => :short_listed_winners, :conditions => 'accepted = true',
      :order => 'short_listed_winners.id'

  has_many :contest_regions, :dependent => :delete_all
  has_many :regions, :through => :contest_regions, :source => :region

  named_scope :pending, :conditions => ['contests.status = ?', STATUS_APPROVAL_PENDING], :order => 'id'
  named_scope :pending_or_drafts, :conditions => ['contests.status in (?)', [STATUS_DRAFT, STATUS_APPROVAL_PENDING]], :order => 'id'
  named_scope :deactivated, :conditions => ['contests.status = ?', STATUS_DEACTIVATED], :order => 'id'
  named_scope :online, :conditions => "contests.status >= #{STATUS_LIVE}" # online means it is accessible but not necessarily listed
  named_scope :live, :conditions => "contests.status = #{STATUS_LIVE}" # live means it is listed
  named_scope :expired, :conditions => "ends_on < now()::date", :order => 'ends_on desc'
  named_scope :running, :conditions => "starts_on <= now()::date and ends_on >= now()::date"
  named_scope :regional, lambda { |region_id| 
      { :conditions => ['contest_regions.region_id = ?', region_id], :joins => 'inner join contest_regions on contests.id = contest_regions.contest_id' }
  }
  named_scope :recent, :order => 'contests.starts_on desc'
  named_scope :featured, :conditions => ['contests.featured = ?', true], :order => 'contests.starts_on desc'
  named_scope :with_prize_points, :conditions => ['loyalty_points_enabled = ?', true], :order => 'contests.starts_on desc'
  named_scope :with_prizes, :select => 'distinct contests.*', :joins => :contest_prizes, :order => 'contests.starts_on desc'
  named_scope :with_prizes_in_region, lambda { |region_id|
      { :select => 'distinct contests.*', :joins => :contest_prizes, :conditions => ['contest_prizes.region_id = ? and contest_prizes.from_date < now() and contest_prizes.to_date >= now()::date', region_id], :order => 'contests.starts_on desc' }
  }
  named_scope :top_rated, :order => 'net_votes desc'
  named_scope :most_favourited, :order => 'favourited desc'
  named_scope :most_played, :order => 'played desc'

  define_index do
    indexes :title
    indexes  :description
    indexes categories.name, :as => :categories
    indexes tags.name, :as => :tags
    indexes [user.first_name, user.last_name, user.username], :as => :user
    indexes "contests.starts_on <= now()::date and contests.ends_on >= now()::date", :as => :running
    indexes "contests.created_on >= now() - interval '1 week'", :as => :this_week
    indexes "contests.created_on >= now() - interval '1 month'", :as => :this_month
    indexes "to_char(contests.created_on, 'YYYYmmddHH24MIss')", :as => :created_on, :sortable => true
    indexes :type, :as => :contest_type
    has contest_regions(:region_id), :as => :region_ids
    where "contests.status = #{STATUS_LIVE}"
    where "contests.ends_on >= now()::date"
  end

  # plugins
  acts_as_taggable

  before_create :generate_slug, :set_version, :set_username
  before_save :override_attributes_from_campaign

  # validations 
  validates_presence_of :title
  validates_size_of :title, :maximum => 100
  validates_size_of :description, :maximum => 350, :allow_nil => true
  validates_presence_of :tag_list, :category_ids, :unless => Proc.new { |c| c.is_a?(Campaign) }
  validates_date :starts_on, :ends_on 

  def validate_on_create
    errors.add_to_base("Starts on cannot be before today!") if starts_on && starts_on < Date.today
    errors.add(:title, 'is invalid') if !title.empty? && title.gsub(/\W+/,'-')[0..99].gsub(/^-|-$/,'').empty?
  end

  def validate
    errors.add_to_base("Ends on cannot be before Starts on!") if ends_on && starts_on && ends_on < starts_on
    if campaign
      unless campaign.applies_to? self.class.name
        errors.add_to_base("#{campaign.title} campaign doesn't support this type of contest!")
      else
        errors.add_to_base("#{campaign.title} campaign is not running!") unless campaign.running?
      end
    end
  end

  def self.new(args = {}) 
    #args.reverse_merge!(:starts_on => Time.now, :ends_on => args.include?(:never_ends) ? Date.new(2020).to_date : (Time.now + 6.months).to_date)
    args.reverse_merge!(:starts_on => Time.now, :ends_on => Date.new(2020).to_date)
    super args
  end

  # Finder scoped to only consider those contests with status as <tt>STATUS_LIVE</tt>
  # and within the start/end date range
  def self.find_live_delme(*args)
    with_scope(:find => { :conditions => "contests.status = #{STATUS_LIVE} and starts_on <= now()::date and ends_on >= now()::date",
        #:order => 'starts_on desc, contests.created_on desc, ends_on asc'
        }) do
      find(*args)
    end
  end  

  # Gets the contests (respecting the type) that match the passed tag.
  def self.find_by_tag(tag, region_id, options = {})
    options[:conditions] << " and contests.type = '#{name}' " unless name == 'Contest'
    options[:conditions] << "and tags.name = tags.name"
    Contest.live.running.regional(region_id).find_tagged_with(tag, options)
  end

  # Gets the tags associated with this Contest type.
  # This builds on top of acts_as_taggable on steroids -
  # http://www.agilewebdevelopment.com/plugins/acts_as_taggable_on_steroids 
  def self.tags(options = {})
    options.reverse_merge!  :order => 'tags.name', :at_least => 2, :at_most => 10
    options[:joins] = 'inner join contest_regions on contest_regions.contest_id = contests.id'
    unless options[:conditions].nil? || options[:conditions].empty?
      if options[:conditions].is_a?(Array)
        conditions = options[:conditions]
      else
        conditions = [options[:conditions]]
      end  
    else
      conditions = [' 1=1 ']
    end  
    conditions[0] += " and contests.type = '#{name}' " unless name == 'Contest'
    conditions[0] += " and contests.status = #{STATUS_LIVE} and starts_on <= now()::date and ends_on >= now()::date"
    options[:conditions] = conditions
    Contest.tag_counts(options)
  end

  def related(size=5)
    begin
      words = keywords.split(',').collect{|w| "(#{w.gsub(/\W+/,' ')})"}.join("|")
      contests = Contest.search(:without => {:id => self.id},
          :conditions => {:tags => words, :running => 't'}, :limit => size + 1, :order => :created_on, :sort_mode => :desc)
      contests.delete_if{|c| c.id == self.id}[0..(size-1)] # :without doesn't seem to be working
    rescue
      []
    end
  end

  def self.find_by_tag2(tag, conditions = {}, page = 1, per_page = 20)
    begin
    conditions.merge!({:tags => tag, :running => 't'})
    conditions.merge!({:contest_type => name}) unless name == 'Contest'
    contests = Contest.search(:conditions => conditions, :page => page, :per_page => per_page, :order => :created_on, :sort_mode => :desc)
    rescue
      []
    end
  end

  # Gets only those attributes that are necessary for creating a url pointing
  # to this conetst.
  def url_attributes(additional_params = {})
    additional_params.reverse_merge!(:action => :play)
    #{:id => id, :slug => slug, :controller => self.class.to_s.tableize} << additional_params
    {:id => to_param, :controller => self.class.to_s.tableize} << additional_params
  end

  # True iff this contest is owned by the specified user and is a draft
  # or <tt>by_user</tt> is at least a moderator.
  def editable?(by_user)
    by_user && (user_id == by_user.id && draft?) || (by_user && by_user.moderator?)
  end

  def deletable?(by_user)
    by_user && (by_user.moderator? || by_user == self.user)
  end

  def latest_response_from_user_id(user_id)
    Response.latest_by_contest_id_and_user_id(id, user_id)
  end

  # Adds or removes a vote for this contest.
  def toggle_vote(user_id)
    if existing_vote = votes.find_by_user_id(user_id)
      votes.destroy(existing_vote)
    else
      votes.create!(:user_id => user_id, :points => 1)
    end  
  end

  # Marks or un-marks a favourited flag for this contest.
  def toggle_favourite(user_id)
    if existing = favourites.find_by_user_id(user_id)
      favourites.delete(existing)
    else
      favourites.create!(:user_id => user_id)
    end  
  end

  def questions_addable?(user)
    return user && !ended?  && ((!locked? && others_can_submit_entries? && live?) || (!locked? && user.id == self.user_id && (live? || draft?)) || user.admin?)
  end

  def scorable?() true end

  def show_others_can_add_option?
    return true
  end

  def has_rankings?
    false
  end

  def started?
    starts_on <= Date.today
  end

  def ended?
    ends_on && ends_on < Date.today
  end

  # We don't actually delete contests, instead we deactivate them. 
  def deactivate(deactivated_by)
    transaction do
      update_attribute(:status, STATUS_DEACTIVATED)
      log(AuditLog::DEACTIVATED, deactivated_by)
    end  
  end

  # This makes live a previously deactivated contest
  def activate(activated_by)
    if STATUS_DEACTIVATED == status
      transaction do  
        update_attribute(:status, STATUS_LIVE)
        log(AuditLog::ACTIVATED, activated_by)
      end
    end
  end
  
  def approve(approved_by)
    transaction do
      all_questions.find_all_by_status(Question::STATUS_APPROVAL_PENDING).each do |question|
        question.approve(approved_by)
      end
      update_attribute(:status, STATUS_LIVE)
      user.credit_account(AppConfig.contest_approved_bonus_credits, "Bonus for creating contest - #{title}")
      log(AuditLog::APPROVED, approved_by)
    end
  end

  def all_videos_converted?
    @all_videos_converted ||= connection.query("select count(*) from questions q inner join videos v on q.video_id = v.id where q.status = #{Question::STATUS_APPROVAL_PENDING} and v.status != #{Video::STATUS_LIVE}
        and q.contest_id = #{id}")[0][0] == '0'
  end

  def live?
    STATUS_LIVE <= status
  end

  # Live and started
  def available?
  	live? && started?
  end

  def approval_pending?
    STATUS_APPROVAL_PENDING == status
  end

  def draft?
    STATUS_DRAFT == status
  end

  # Gets the number of questions that are pending approval
  def pending_count
   all_questions.find(:all, :conditions => ["status = #{Question::STATUS_APPROVAL_PENDING}"]).size 
  end

  def question_with_image
    questions.find(:first, :conditions => "content_type != 'Text'", :order => 'id desc')
  end

  def contest_prize
    contest_prizes.pending(:first)
  end

  def has_prizes?
    @has_prizes ||= contest_prizes.count > 0
  end

  def can_have_responses?
    true
  end

  def can_have_questions?
    true
  end

  def to_xml(options = {})
    super(options.reverse_merge!({:methods => [:number_of_questions], :only => [:title, :locked, :description, :id, :type, :ends_on, :created_on, :played, :others_can_submit_entries],
        :skip_types => true})) do |xml|
      xml.creator username
      xml.tag! 'base-url', "http://#{options[:base_url]}/#{self.class.to_s.tableize}/#{id}-#{slug}"      
      if options[:current_user].nil? && login_required
        xml.tag! 'login-required', "http://#{options[:base_url]}/account/login?return_url=" + CGI.escape("http://#{options[:base_url]}/#{self.class.to_s.tableize}/#{id}-#{slug}")
      end
      if image = question_with_image
        if image.content_type == Contest::CONTENT_TYPE_YT_VIDEO
          xml.image image.external_video_img_url
        elsif image.content_type == Contest::CONTENT_TYPE_VIDEO
          video = image.video
          host = video.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
          xml.image "#{host}/#{video.image_web_path('thumb')}"
        else          
          host = image.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"
          xml.image "#{host}/#{image.image_web_path('thumb')}"
        end  
      else
        if skin
          if skin.image_in_s3?
            xml.image "#{FileColumn::S3FileColumnExtension::Config.s3_distribution_url}/#{skin.image_web_path}"
          else
            xml.image "http://#{options[:base_url]}/uploads/skin/image/#{skin.image_relative_path}?#{skin.updated_on.to_i}"
          end
        end
      end
      if options[:brief].nil?
        xml.skin "http://#{options[:base_url]}/uploads/skin/file/#{skin.file_relative_path}?#{skin.updated_on.to_i}" if skin
        if options[:region] == 'in' && brand
          if brand.logo_in_s3?
            xml.tag!('brand-logo', "#{FileColumn::S3FileColumnExtension::Config.s3_distribution_url}/#{brand.logo_web_path}")
          else
            xml.tag!('brand-logo', "http://#{options[:base_url]}/#{brand.logo_web_path}")
          end
          xml.tag!('brand-url', self.brand.url) unless self.brand.url.blank?
        end
        xml.tag!('share-url', "http://#{options[:base_url]}/#{self.class.name.tableize}/#{id}-#{slug}/share")
        xml.tag!('tray-url', "http://#{options[:base_url]}/flvplayer/tray.swf")
        xml.tag!('font-lib-url', "http://#{options[:base_url]}/flvplayer/fonts.swf")
      end
      xml.embed render_flash_for_contest(self, true, options[:base_url])
    end
  end

  def to_json(options = {})
    j = attributes.reject{|k,v| not %w(id title description type, ends_on, played, net_votes, ends_on).include?(k)}
    j.merge!( :embed => render_flash_for_contest(self, true, options[:base_url]),
      :creator => username,
      :categories => categories.collect(&:name),
      :playing_instructions => (skin.description rescue nil),
      :number_of_questions => number_of_questions,
      'base_url' => "http://#{options[:base_url]}/#{self.class.to_s.tableize}/#{id}-#{slug}"
    )
    if image = question_with_image
      if image.content_type == Contest::CONTENT_TYPE_YT_VIDEO
        j[:image] = image.external_video_img_url
      elsif image.content_type == Contest::CONTENT_TYPE_VIDEO
        j[:image] = "http://#{options[:base_url]}/uploads/video/image/#{image.video.image_relative_path('thumb')}"
      else
        question_or_entry = 'question'
        if image.image_in_s3?
          s3_url = FileColumn::S3FileColumnExtension::Config.s3_distribution_url
          j[:image] = "#{s3_url}/#{image.image_web_path('thumb')}"
        else
          j[:image] = "http://#{options[:base_url]}/uploads/#{question_or_entry}/image/#{image.image_relative_path('thumb')}"
        end 
      end  
    else
      if skin
        if skin.image_in_s3?
          j[:image] = "#{FileColumn::S3FileColumnExtension::Config.s3_distribution_url}/#{skin.image_web_path(nil)}"
        else
          j[:image] = "http://#{options[:base_url]}/uploads/skin/image/#{skin.image_relative_path(nil)}"
        end
      end
    end

    {self.class.name.downcase => j}.to_json
  end

  def before_validation
    self.starts_on = Date.today.to_time unless self.starts_on
    self.ends_on = Date.new(2020).to_time if never_ends?
  end

  def never_ends?
    'true' == never_ends || (ends_on && ends_on.to_date.to_s >= '2020-01-01')
  end

  def never_expires?
    if @never_ends
      @never_ends
    else
      Date.new(2020) == ends_on
    end  
  end

  def never_ends
    unless @never_ends
      never_expires? ? 1:0
    else
      @never_ends
    end  
   end

  def top_scorers(options)
    options.reverse_merge!({:from => self.starts_on, :to => self.ends_on, :limit => 60})
    sql = "select user_id, score, date_trunc('second', COALESCE(responses.finished_on, now()) - responses.created_on) as time_taken from responses inner join users on users.id = responses.user_id
      where contest_id = #{self.id} and users.region_id = #{options[:region_id]}
      and responses.created_on between '#{options[:from].strftime('%Y-%m-%d')}' and '#{options[:to].to_time.strftime('%Y-%m-%d 23:59:59.99999')}' "
    if options[:exclude_users_sql]
      sql << " and user_id not in (#{options[:exclude_users_sql]})"
    end
    sql << " order by score desc, time_taken asc limit #{options[:limit]}"
    connection.execute(sql)
  end

  def embeddable?
    true
  end

  def loyalty_points_applicable?
    running? && loyalty_points_enabled? rescue false
  end

  # Call when the user is done with adding questions to the contest.
  # Switches the status of this contest from DRAFT to APPROVAL_PENDING iff this contest was just created 
  def finished_creating
    update_attribute(:status, STATUS_APPROVAL_PENDING) if draft?
  end

  def to_param
    "#{id}-#{slug}"
  end

  def running?
    started? && !ended?
  end

  # Permanently deletes associated questions/entries.
  # Contests themselves cannot be deleted if there are winners associated with them.
  def purge
    raise "Cannot purge cos contest hasn't been DELETED" unless status == STATUS_DELETED
    unless short_listed_winners.empty?
      all_questions.destroy_all
      responses.delete_all
      votes.delete_all  
      favourites.delete_all  
      all_comments.delete_all  
      update_attribute(:status, STATUS_PURGED)
    else
      self.destroy
    end
  end

  def self.purge_deleted
    find(:all, :conditions => ['status = ?', STATUS_DELETED]).each do |c|
      c.purge 
    end
  end

  def add_audit_log(action, user)
    log(action, user)
  end
  
  def default_image(base_url = nil)
    base_url ||= begin
      case RAILS_ENV
        when 'production' then 'c2w.com'
        when 'staging' then 'staging.c2w.com'
        when 'development' then 'c2w.nikhilgupte.com'
      end
    end
    if image = question_with_image
      if image.content_type == Contest::CONTENT_TYPE_YT_VIDEO
        return image.external_video_img_url
      elsif image.content_type == Contest::CONTENT_TYPE_VIDEO
        return "http://#{base_url}/uploads/video/image/#{image.video.image_relative_path('thumb')}"
      else
        question_or_entry = 'question'
        if image.image_in_s3?
          s3_url = FileColumn::S3FileColumnExtension::Config.s3_distribution_url
          return "#{s3_url}/#{image.image_web_path('thumb')}"
        else
          return "http://#{base_url}/uploads/#{question_or_entry}/image/#{image.image_relative_path('thumb')}"
        end 
      end  
    else
      if skin
        if skin.image_in_s3?
          return "#{FileColumn::S3FileColumnExtension::Config.s3_distribution_url}/#{skin.image_web_path(nil)}"
        else
          return "http://#{base_url}/uploads/skin/image/#{skin.image_relative_path(nil)}"
        end
      end
    end
  end

  def cta_text
    "Play #{title}"
  end

  protected
  # Gets the tags or the title (as csv) if there are no tags.
  def keywords
    unless tag_list.empty?
      tag_list
    else  
      title.gsub(/\W+/,', ').downcase
    end  
  end

  # Convenience method for XMLized view to get the number of questions in
  # this contest.
  def number_of_questions
    questions.count
  end

  def has_questions?
    all_questions.first.present?
  end

  def after_find
    self.never_ends = ends_on.to_date.to_s >= '2020-01-01' if self.has_attribute?(:ends_on)
  end

  def find_winnings_by_user_id(user_id)
    short_listed_winners.find_all_by_user_id(user_id)
  end

  def response_caption
    "I played the '#{self.title}' #{self.type.humanize}"
  end

  private
  def set_username
    self.username = user.username
  end

  # Generates a search engine firendly <tt>slug</tt>
  # whcih is added as a part of the URL - http://c2w.com/contest/id/<tt>slug</tt>/
  def generate_slug
    write_attribute(:slug, title.gsub(/\W+/,'-')[0..99].gsub(/^-|-$/,''))
  end

  def set_version  
    write_attribute :version_number, "#{APP_VERSION.major}.#{APP_VERSION.minor}" 
  end  

  def override_attributes_from_campaign
    if campaign
      self.skin_id = campaign.contest_type(self.class.name).skin_id
      #self.brand_url = campaign.brand_url
      self.brand_id = campaign.brand_id
    end
  end
end
