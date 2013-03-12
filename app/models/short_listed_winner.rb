class ShortListedWinner < ActiveRecord::Base

  belongs_to :user
  belongs_to :contest_prize
  belongs_to :entry, :polymorphic => true

  acts_as_auditable

  named_scope :latest_winners, :conditions => ['accepted = ?', true], :order => 'id desc'
  named_scope :latest_winners_in_region, lambda { |region_id|
      { :select => 'distinct short_listed_winners.*', :joins => :user, :conditions => ['users.region_id = ? and accepted = ?', region_id, true], :order => 'short_listed_winners.id desc' }
  }
  def confirmed?
    ! confirmed_on.nil?
  end

  def rejected?
    accepted == false
  end

  def confirm_by_date
    created_on + AppConfig.prize_expires_after_in_days.days
  end

  def expired?
    not(confirmed?) and confirm_by_date.to_date < Date.today
  end

  def status
    if accepted?
      'Accepted'
    elsif rejected?
      'Rejected'
    elsif expired?
      'Expired'
    else
      'Pending'
    end  
  end

  def pending?
   !(expired? || confirmed?) 
  end

  def prize
    contest_prize.prize
  end

end
