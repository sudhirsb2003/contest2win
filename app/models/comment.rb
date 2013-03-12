class Comment < ActiveRecord::Base
  attr_protected :user_id, :commentable_id
  acts_as_auditable

  named_scope :pending, :conditions => 'status is null', :order => :id
  before_create :set_username

  # validations 
  validates_presence_of :message
  validates_size_of :maximum => 50
  validates_size_of :message, :maximum => 1000
    
  # associations
  belongs_to :user
  belongs_to :contest, :foreign_key => :commentable_id

  STATUS_LIVE = 1
  STATUS_DISABLED = -1
  STATUS_APPROVAL_PENDING = nil

  def live?
    status == STATUS_LIVE
  end

  def approve(approved_by)
    transaction do  
      update_attribute(:status, STATUS_LIVE)
      log(AuditLog::APPROVED, approved_by)
    end  
  end

  def self.count_pending(*args)
    with_scope(:find => {:conditions => 'status is null' }) do
      count(*args)
    end
  end

  def deleteable?(user)
    #user && (user == self.user || user == contest.user || user.moderator?)
    #user && user.moderator?
    user && ((user.id == contest.user_id && !sticky?) || user.moderator?)
  end

  private
  def set_username
    self.username = user.username
  end

end
