class PrizeCategory < ActiveRecord::Base

  validates_presence_of :name
  validates_size_of :name, :maximum => 30, :allow_nil => true
  def self.find_available
    find(:all, :order => :name)
  end

  def to_s
    name
  end
end
