class Personality < ActiveRecord::Base

  validates_presence_of :title, :minimum_score, :maximum_score
  validates_size_of :title, :maximum => 50
  validates_size_of :description, :maximum => 255
  validates_numericality_of :minimum_score, :maximum_score, :allow_nil => true

  belongs_to :contest

  validates_filesize_of :image, :in => 0..600.kilobytes
  validates_file_format_of :image, :in => ["jpg", "gif", "png"]
  file_column :image, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :magick => {
    :geometry => "180x130>",
    :versions => {
      :thumb => {:geometry => '60x60>'}
    }
  }

  def to_xml(options = {})
    super(options.reverse_merge!({:only => [:title, :id], :skip_types => true})) do |xml|
      if image
        host = image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"
        xml.image "#{host}/#{image_web_path('thumb')}"
      end
      xml.tag! 'contest-url', "http://#{options[:base_url]}/#{contest.class.to_s.tableize}/#{contest.id}-#{contest.slug}"      
      xml.tag! 'contest-title', contest.title
      xml.tag! 'similar-users', similar_users
    end
  end

  def similar_users
    ((number_of_users/contest.played.to_f)*100.0).round(2)
  end

  def editable?(user)
    contest.user == user || user.admin?
  end

  def deletable?(user) editable?(user) end
end
