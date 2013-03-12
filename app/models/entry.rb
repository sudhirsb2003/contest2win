class Entry < ActiveRecord::Base
  include Auditable::Acts::Audited

  # constants
  STATUS_LIVE = 1
  STATUS_APPROVAL_PENDING = 0
  STATUS_DRAFT = -1

  named_scope :pending, :include => [:faceoff], :conditions => ['entries.status = ? and contests.status = ?', STATUS_APPROVAL_PENDING, Contest::STATUS_LIVE], :order => 'entries.id'
  named_scope :pending_or_drafts, :include => :faceoff,
      :conditions => ['entries.status in (?) and contests.status = ?', [STATUS_DRAFT, STATUS_APPROVAL_PENDING], Contest::STATUS_LIVE]

  # associations
  belongs_to :faceoff
  belongs_to :user
  belongs_to :video
  has_many :options, :class_name => "QuestionOption"
  has_many :questions, :through => :options
  has_many :ranked_entries

  acts_as_auditable

 # validations
  validates_presence_of :title
  validates_size_of :title, :maximum => 47
  validates_size_of :description, :maximum => 2000, :if => Proc.new {|entry|
    Contest::CONTENT_TYPE_TEXT == entry.faceoff.content_type
  }
  validates_presence_of :image, :if => Proc.new {|entry|
    Contest::CONTENT_TYPE_IMAGE == entry.faceoff.content_type
  }
  validates_presence_of :video, :if => Proc.new {|entry| Contest::CONTENT_TYPE_VIDEO == entry.content_type }
  validates_presence_of :external_video_url, :if => Proc.new {|q| q.content_type == Contest::CONTENT_TYPE_YT_VIDEO}
  validates_presence_of :description, :if => Proc.new {|entry|
    Contest::CONTENT_TYPE_TEXT == entry.faceoff.content_type
  }
  validates_filesize_of :image, :in => 0..600.kilobytes    
  validates_file_format_of :image, :in => ["jpg", "gif", "png"]
  def validate
      unless self.external_video_url.blank? 
        errors.add(:external_video_url, "is not valid.") if self.external_video_url.split("?v=").length <= 1
      end
  end


  attr_protected :user_id, :faceoff_id

  before_create :set_username

  # plugins 
  file_column :image, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :magick => {
    :geometry => "400x400>",
    :versions => {
          :thumb => {:geometry => '60x60>'},
          :medium => {:geometry => '240x180>'}
    }
  }

  def editable?(by_user)
    #user && user.moderator? || (STATUS_LIVE != status && user == self.user)
    (user == by_user && draft?) || (by_user && by_user.moderator?)
  end

  def deletable?(user)
    user && (user.moderator? || user == self.user || user == self.faceoff.user)
  end

  def live?
    STATUS_LIVE == status
  end

  # Deletes all questions made from this entry... 
  def before_destroy
    Question.delete_all("id in
      (SELECT q.id from questions q, question_options o where o.question_id = q.id and o.entry_id = #{id})")
  end

  def approve(approved_by)
    transaction do
      faceoff.generate_questions_for_entry(self)
      update_attribute(:status, Entry::STATUS_LIVE)
      connection.execute "UPDATE question_options set text = (select title from entries where id = #{id}) WHERE entry_id = #{id}",
            "Update the question options text with the new title of the entry"
      log(AuditLog::APPROVED, approved_by)
    end
  end  

  def contest() faceoff end
  def contest_id() faceoff_id end

  def draft?
    STATUS_DRAFT == status
  end

  def set_video(attr)
    return nil if attr.nil? || (attr[:original_file_temp].blank? && attr[:original_file].blank?)
    #video.destroy if video
    video = build_video attr
    video.title = title
    video.created_by_id = user_id
    video
  end

  #def video_url
    #video ? video.streaming_path : self[:video_url]
  #end

  def has_video?
    #video_id || (contest.content_type == 'Video' && !video_url.nil?)
    video
  end

  def is_external?
    false
  end

  def to_xml(options ={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.entry do
      xml.creator user.username
      xml.tag!('content-type', content_type)
      xml.title title
      xml.total_points total_points
      xml.id id
      case content_type
      when Contest::CONTENT_TYPE_IMAGE
        xml.image do
          if image_in_s3?
            s3_url = FileColumn::S3FileColumnExtension::Config.s3_distribution_url
            xml.thumbnail "#{s3_url}/#{image_web_path('thumb')}"
            xml.medium "#{s3_url}/#{image_web_path('medium')}"
            xml.large "#{s3_url}/#{image_web_path}"
          else
            xml.thumbnail "http://#{options[:base_url]}/#{image_web_path('thumb')}"
            xml.medium "http://#{options[:base_url]}/#{image_web_path('medium')}"
            xml.large "http://#{options[:base_url]}/#{image_web_path}"
          end
        end
      when Contest::CONTENT_TYPE_VIDEO
        if video
          xml.image do
            host = video.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
            xml.thumbnail "#{host}/#{video.image_web_path('thumb')}"
            xml.medium "#{host}/#{video.image_web_path()}"
          end
          if video
            host = video.stream_file_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"            
            xml.video "#{host}/#{video.stream_file_web_path}"
          else
            xml.video video_url
          end
        end

      when Contest::CONTENT_TYPE_YT_VIDEO
        xml.tag!('video-url', external_video_url)
        xml.thumbnail external_video_img_url
      end
    end
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

  def before_validation
    self.external_video_url.strip! if self.external_video_url
  end

  def self.upload_to_s3(limit = 1000)
    move_all_images_to_s3(:conditions => ['image is not null and image_in_s3 = ? and status = ?', false, STATUS_LIVE], :limit => limit)
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
    when Contest::CONTENT_TYPE_IMAGE
      if image_in_s3?
        s3_url = FileColumn::S3FileColumnExtension::Config.s3_distribution_url
        return "#{s3_url}/#{image_web_path('thumb')}"
      else
        return "http://#{base_url}/#{image_web_path('thumb')}"
      end
    when Contest::CONTENT_TYPE_VIDEO
      if video
        host = video.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{base_url}"
        return "#{host}/#{video.image_web_path('thumb')}"
      end
    when Contest::CONTENT_TYPE_YT_VIDEO
      return external_video_img_url
    end
    nil
  end

  private
  def set_username
    self.username = user.username
  end

end
