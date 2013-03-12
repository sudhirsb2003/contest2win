require 'digest/md5'
class Question < ActiveRecord::Base
  include Auditable::Acts::Audited
  acts_as_auditable

  # constants
  STATUS_LIVE = 1
  STATUS_APPROVAL_PENDING = 0
  STATUS_DRAFT = -1

  BETTING_STATUS_DECLARED = 10
  BETTING_STATUS_SETTLED = 20

  named_scope :pending, :joins => :contest, :conditions => ['questions.status = ? and contests.status = ?', STATUS_APPROVAL_PENDING, Contest::STATUS_LIVE], :order => 'questions.id'
  named_scope :pending_or_drafts, :include => :contest,
    :conditions => ['questions.status in (?) and contests.status = ?', [STATUS_DRAFT, STATUS_APPROVAL_PENDING], Contest::STATUS_LIVE]
  named_scope :ranked, :select => 'questions.*, total_rating/answers_count::real as avg_rating',
    :order => 'avg_rating', :conditions => "status = #{Question::STATUS_LIVE} and answers_count > 0"
  
  named_scope :for_prediction, :select => '*, ends_on < now() as ended', :conditions => ['status >= ?', Question::STATUS_LIVE]

  # validations 
  validates_presence_of :question
  validates_inclusion_of :content_type, :in => [Contest::CONTENT_TYPE_YT_VIDEO, Contest::CONTENT_TYPE_VIDEO, Contest::CONTENT_TYPE_IMAGE, Contest::CONTENT_TYPE_TEXT]
  validates_presence_of :external_video_url, :if => Proc.new {|q| q.content_type == Contest::CONTENT_TYPE_YT_VIDEO}
  validates_presence_of :video, :if => Proc.new {|q| q.content_type == Contest::CONTENT_TYPE_VIDEO}
  validates_size_of :question, :maximum => 100 
  validates_size_of :hint, :maximum => 100, :allow_nil => true

  validates_each :options do |rec, name, value|
    tmp = value.collect{|option| option.text.strip}
    label = rec.contest.is_a?(Hangman) ? 'Answer' : 'Options'
    rec.errors.add label, ' cannot be left blank' if tmp.include?('') && ! %w(Crossword).include?(rec.contest.class.name)
  end

  validates_each :options do |rec, name, value|
    rec.errors.add name, 'must be between 2 and 5!' unless (2..5).include?(value.size) || %w(Hangman).include?(rec.contest.class.name)
  end
  validates_filesize_of :image, :in => 0..600.kilobytes
  validates_file_format_of :image, :in => ["jpg", "gif", "png"]

  def validate
    errors.add_to_base("A correct option must be specified ") \
      if contest.is_a?(Quiz) && options.inject(0) { |sum, option| sum += (option.points||0)*(option.points||0)  } <= 0
    # I'm squaring the above to ensure that at least one option is non-zero; which is the criteria to ensure
    # a correct option is selected.
    unless self.external_video_url.blank?
      errors.add(:external_video_url, "is not valid.") if self.external_video_url.split("?v=").length <= 1
    end
  end

  attr_protected :user_id, :contest_id

  # associations
  has_many :options, :class_name => "QuestionOption", :order => :position, :dependent => :delete_all
  has_many :entries, :through => :options, :order => 'entries.id asc'
  has_many :answers
  belongs_to :contest
  belongs_to :user
  belongs_to :video
  

  # plugins 
  file_column :image, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :magick => {
    :geometry => "400x400>",
    :versions => {
      :thumb => {:geometry => '60x60>'},
      :medium => {:geometry => '240x180>'}
    }
  }

  before_create :set_username

  def editable?(by_user)
    by_user && ((user_id == by_user.id && draft?) || (by_user && by_user.moderator?))
  end

  def deletable?(user)
    user && (user.moderator? || (user.id == self.user_id || user.id == self.contest.user_id) && !self.contest.locked?)
  end

  def add_or_update_options(submitted_options)
    if submitted_options
      submitted_options.each_value do |submitted_option|
        add_or_update_option(submitted_option)
      end
    end
  end
  
  def approve(approved_by)
    transaction do
      update_attribute(:status, Question::STATUS_LIVE)
      log(AuditLog::APPROVED, approved_by)
    end  
  end  

  def add_or_update_option(submitted_option)
    options.each do |option|
      if option.id.to_i == submitted_option[:id].to_i
        option.update_attribute(:text, submitted_option[:text])
        option.update_attribute(:points, submitted_option[:points]) if submitted_option[:points]
        option.save
        return
      else
      end
    end
    options << QuestionOption.new(submitted_option)
  end

  def live?
    STATUS_LIVE == status
  end

  def correct_option
    options.each {|option| return option if option.correct?}
    return nil
  end

  def popular_option
    options.find(:first, :order => 'clicks desc')
  end

  # used to hide characters in hangman.
  def fill_in_the_blanks(guessed = '')
	  remainder = ('A'..'Z').to_a + ('0'..'9').to_a - guessed.upcase.split(//)
  	answer.upcase.tr(remainder.to_s, '_')
  end

  # Gets the correct option's text, which is assumed to be the first option with positive points.
  def answer
    corect_options = options.collect{|o| o if o.points > 0}
    unless corect_options.empty?
      corect_options.first.text
    else  
      nil
    end
  end

  def answer=(a)
    connection.execute("DELETE from question_options where question_id = #{id}") if id
    a = a.gsub(/( )+/,' ').strip #remove exrta spaces
    option = options.build(:text => a)
    option.points = 1
    option
  end

  def before_validation
    question.strip! unless question.nil?
    if Contest::CONTENT_TYPE_IMAGE == self.content_type
      self.content_type = Contest::CONTENT_TYPE_TEXT if self.image.blank?
      self.external_video_url = nil
    end
    self.external_video_url.strip! if self.external_video_url
  end

  def to_xml(options ={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.question do
      xml.id id
      xml.tag!('average-rating', average_rating) if options[:include].include?(:average_rating) rescue nil
      xml.question question
      xml.creator user.username
      xml.hint hint unless hint.blank?
      media_question = self
      if self.reuse_previous_media? && (prev_question = self.previous_question_with_reusable_media).present?
        media_question = prev_question
      end
      xml.tag!('content-type', media_question.content_type)
      case media_question.content_type
      when Contest::CONTENT_TYPE_YT_VIDEO
        xml.tag!('video-url', media_question.external_video_url)
        xml.thumbnail media_question.external_video_img_url
      when Contest::CONTENT_TYPE_VIDEO
        if media_question.video
          xml.image do
            host = media_question.video.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
            xml.thumbnail "#{host}/#{media_question.video.image_web_path('thumb')}"
            xml.medium "#{host}/#{media_question.video.image_web_path()}"
          end
          #xml.video video_url.starts_with?('http://') ? video_url : "http://#{options[:base_url]}#{video_url}"
          if media_question.video
            host = media_question.video.stream_file_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
            xml.video "#{host}/#{media_question.video.stream_file_web_path}"
          else
            xml.video media_question.video_url
          end
        end
      when Contest::CONTENT_TYPE_IMAGE
        xml.image do
          if media_question.image
            host = image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
            xml.thumbnail "#{host}/#{media_question.image_web_path('thumb')}"
            xml.medium "#{host}/#{media_question.image_web_path('medium')}"
            xml.large "#{host}/#{media_question.image_web_path}"
          end
        end
      end

      if !['Hangman'].include? contest[:type]
        xml.options do
          the_options = self.options
          the_options.each do |opt|
            xml.option do
              xml.id opt.id
              xml.text opt.text
              if entry = opt.entry
                xml.entry do
                  xml.tag!('content-type', entry.content_type)
                  case entry.content_type
                  when Contest::CONTENT_TYPE_VIDEO
                    xml.image do
                      host = entry.video.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
                      xml.thumbnail "#{host}/#{entry.video.image_web_path('thumb')}"
                      xml.medium "#{host}/#{entry.video.image_web_path}"
                    end
                    #xml.video opt.entry.video_url.starts_with?('http://') ? opt.entry.video_url : "http://#{options[:base_url]}#{opt.entry.video_url}" unless opt.entry.video_url.nil?
                    if entry.video
                      host = entry.video.stream_file_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
                      xml.video "#{host}/#{entry.video.stream_file_web_path}"
                    else
                      xml.video entry.video_url
                    end

                  when Contest::CONTENT_TYPE_IMAGE
                    xml.image do
                      host = opt.entry.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"                      
                      xml.thumbnail "#{host}/#{opt.entry.image_web_path('thumb')}"
                      xml.medium "#{host}/#{opt.entry.image_web_path('medium')}"
                      xml.large "#{host}/#{opt.entry.image_web_path}"
                    end
                  when Contest::CONTENT_TYPE_YT_VIDEO
                    xml.tag!('video-url', entry.external_video_url)
                    xml.thumbnail entry.external_video_img_url
                  end
                  xml.description opt.entry.description if content_type == 'Text'
                end
              end  
            end
          end
        end
      elsif contest.is_a?(Hangman)
        xml.tag!('fill-in-the-blanks', options[:fill_in_the_blanks])
        xml.tag!('points-available', options[:points_available])
        xml.tag!('guesses-right', options[:guesses_right])
        xml.tag!('guesses-wrong', options[:guesses_wrong])
      end
    end    
  end

  def self.find_with_image(*args)
    with_scope(:find => { :conditions => "questions.content_type != '#{Contest::CONTENT_TYPE_TEXT}' and questions.status = #{STATUS_LIVE} and contests.status = #{Contest::STATUS_LIVE} and contests.starts_on <= now()::date and contests.ends_on >= now()::date
      and (questions.image is not null or questions.external_video_url is not null or questions.video_id is not null)", :include => :contest, :order => 'questions.id desc'
      }) do
      find(*args)
    end
  end

  def number_of_answers
  	@number_of_answers ||= answers.count
  end

  def average_rating
    answers_count > 0 ? (total_rating.to_f / answers_count.to_f).round_to(2) : 0
  end

  def set_video(attr)
    return nil if attr.nil? || (attr[:original_file_temp].blank? && attr[:original_file].blank?)
    video = build_video attr
    video.title = question
    video.created_by_id = user_id
    video
  end

  #def video_url
    #video ? video.streaming_path : self[:video_url]
  #end

  def has_video?
    video
  end

  def draft?
    STATUS_DRAFT == status
  end

  def external_video_img_url
    "http://i.ytimg.com/vi/#{external_video_id}/default.jpg"
  end

  def external_video_id
    @external_video_id ||= begin
      a = external_video_url.split("?v=") 
      b = a[1].split("&")
      b[0]
    rescue
      'error'
    end  
  end

  def is_external?
    not external_video_url.blank?
  end

  def digest
    Digest::MD5.hexdigest(answer)
  end

  def title
    question
  end

  def total_wager() total_rating end

  def self.upload_to_s3
    move_all_images_to_s3(:conditions => ['image is not null and image_in_s3 = ? and status = ?', false, STATUS_LIVE])
  end
  
  # open for accepting bets
  def open?
    ends_on > Time.now
  end

  def soft_delete(user)
    if deletable?(user)
      super
    end
  end
  def escape_sql(str)
    str.gsub(/\\|'/) { |c| "\\#{c}" }
  end

  def default_image
    base_url ||= begin
      case RAILS_ENV
        when 'production' then 'c2w.com'
        when 'staging' then 'staging.c2w.com'
        when 'development' then 'c2w.nikhilgupte.com'
      end
    end

    case content_type
    when Contest::CONTENT_TYPE_YT_VIDEO
      return external_video_img_url
    when Contest::CONTENT_TYPE_VIDEO
      if video
        host = video.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{base_url}"
        return "#{host}/#{video.image_web_path('thumb')}"
      end
    when Contest::CONTENT_TYPE_IMAGE
      if image
        host = image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{base_url}"
        return "#{host}/#{image_web_path('thumb')}"
      end
    end
  end

  def previous_question_with_reusable_media
    contest.questions.first(:conditions => ["id < ? and content_type <> ?", id, Contest::CONTENT_TYPE_TEXT], :order => "id DESC")
  end

  private
  def set_username
    self.username = user.username
  end

  def short_identifier
    s = "#{contest.title}/#{title}"
    "#{s[0..150]} (#{id})"
  end

end
