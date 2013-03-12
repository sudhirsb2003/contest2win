#-- $Id: skin.rb 2813 2009-01-08 13:11:14Z ngupte $
#++
#
# A Skin is the UI applied to a contest
# 
class Skin < ActiveRecord::Base
  
  CONTEST_TYPES = %w(Quiz Hangman Crossword PersonalityTest).sort!

  named_scope :all, :order => 'name'

  has_many :contests

  validates_presence_of :image, :file, :name,  :contest_type
  validates_size_of :name, :within => 0..30, :allow_nil => true
  validates_size_of :description, :within => 0..500, :allow_nil => true
  validates_uniqueness_of :name

  validates_filesize_of :image, :in => 0..600.kilobytes    
  validates_file_format_of :image, :in => ["jpg", "gif", "png"]

  validates_filesize_of :file, :in => 0..1024.kilobytes
  validates_file_format_of :file, :in => ["swf"]

  file_column :file, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true
  file_column :image, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :s3_auto => :move, :magick => {:geometry =>  '60x60>'}

  def before_validation
    self.name = name.strip unless name.nil?
    self.description = description.strip unless description.nil?
  end

  def self.find_by_type(type, user)
    find(:all, :conditions => ["contest_type = ? and expired = false #{'and only_admin = false' unless user.admin?}", type.to_s], :order => 'name asc')
  end

  def deletable?
    contests.count == 0
  end

  def no_flash?
    "NOFLASH" == name.upcase
  end
end
