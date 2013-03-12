#-- $Id: brand.rb 2138 2008-07-16 20:36:30Z ngupte $
#++
#
# A Skin is the UI applied to a contest
# 
class Brand < ActiveRecord::Base
  
  has_many :contests

  validates_presence_of :logo, :name
  validates_size_of :name, :within => 0..100, :allow_nil => true
  validates_size_of :url, :within => 0..255, :allow_nil => true
  validates_uniqueness_of :name

  validates_filesize_of :logo, :in => 0..20.kilobytes
  validates_file_format_of :logo, :in => ["jpg", "gif", "png"]

  file_column :logo, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :s3_auto => :move

  def before_validation
    self.name = name.strip unless name.nil?
  end

  def self.find_available
    find(:all, :conditions => ['expired = false'], :order => 'name asc')
  end

  def deletable?
    contests.count == 0
  end

end
