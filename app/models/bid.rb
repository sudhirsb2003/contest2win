class Bid < ActiveRecord::Base
  belongs_to :user
  belongs_to :contest_prize
  belongs_to :toppled_by, :class_name => 'User', :foreign_key => 'toppled_by_id'

  #validates_presence_of :value
  validates_numericality_of :value
  validates_uniqueness_of :value, :scope => [:contest_prize_id, :user_id], :message => 'has already been submitted by you!'
  def validate_on_create
    if contest_prize.bids.count(user_id, :conditions => "user_id = #{user_id} and toppled_by_id is null") >= 5
      errors.add_to_base('You have exceeded your maximum number of bids!')
    elsif not value.nil?
      errors.add_to_base('Bid value cannot be less than 0') if value < 0
      errors.add_to_base('Bid value cannot be more than 1,000,000') if value > 1000000
      errors.add_to_base('Bid value cannot contain more than 2 digits after the decimal point') if (value * 100).to_s.to_i != (value * 100).to_s.to_f
    end
  end

  def toppled?
    not toppled_by_id.nil?
  end

  def topple(toppled_by_id)
    update_attribute(:toppled_by_id, toppled_by_id)
  end

  def reverse_auction
    contest_prize.contest
  end

end
