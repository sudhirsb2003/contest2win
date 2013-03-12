class Region < ActiveRecord::Base
  validates_presence_of :domain_prefix, :name
  validates_size_of :domain_prefix, :maximum => 3
  validates_size_of :name, :maximum => 50
  validates_uniqueness_of :domain_prefix, :case_sensitive => false

  has_and_belongs_to_many :categories

  DEFAULT_ID = 1

  def before_validation
    unless domain_prefix.blank?
      domain_prefix.downcase!
      domain_prefix.strip!
    end
    name.strip! if name
  end

  def self.find_by_domain_prefix_or_default(country_code)
    Region.find(:first, :conditions => ["domain_prefix in (?, 'www')", country_code], :order => 'id desc')
  end

  #def self.default(country_code)
    #Region.find DEFAULT_ID
  #end

  def self.not_in(ids)
    ids.empty? ? all : find(:all, :conditions => ['id not in (?)', ids])
  end

  def www?
    id == DEFAULT_ID
  end

  def india?
    domain_prefix == 'in'
  end
end
