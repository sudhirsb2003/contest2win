require 'RMagick'
#-- $Id: contest.rb 917 2008-01-07 07:42:49Z ngupte $
#++
#
# Videos are stored in an independant respository.
# By default, the streaming file isn't present for a video. Periodically
# the database is scanned for videos who don't have a streaming file and the
# same is genereated.
#
# +Entry+s and +Question+s can have a video associated to them. Two or more Question/Entry can have
# the same video.
#
# If a video is marked as +shared+, it can be selected by other users for their contests.
#
class Video < ActiveRecord::Base
  VALID_INPUT_FILE_FORMATS = %w(FLV WMV AVI MPG MPEG MP4 MOV ASF 3GP)
  STATUS_CONVERSION_PENDNG = 0
  STATUS_PROCESSING = -10
  STATUS_ERROR = -100
  STATUS_LIVE = 10
  STATUS_DELETED = -1000

  validates_filesize_of :original_file, :in => 1..20.megabytes
  validates_file_format_of :original_file, :in => VALID_INPUT_FILE_FORMATS + VALID_INPUT_FILE_FORMATS.collect {|e| e.downcase}
  validates_filesize_of :image, :in => 0..600.kilobytes
  validates_file_format_of :image, :in => ["jpg", "gif", "png"]
  validates_presence_of :original_file

  file_column :original_file, :web_root => "uploads/", :root_path => "public/uploads"
  file_column :stream_file, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true
  file_column :image, :web_root => "uploads/", :root_path => "public/uploads", :s3 => true, :magick => {
    :geometry => "240x180>",
    :versions => { :thumb => {:geometry => '60x60>'} }
  }


  def self.convert_pending
    find(:all, :conditions => "status = #{STATUS_CONVERSION_PENDNG}").each do |video|
      video.convert
    end
  end

  # Converts te video into FLV.
  # Only those vidoes that aren't converted are processed unless the +force+ flag is set. 
  def convert(force = false)
    return false if !force && STATUS_CONVERSION_PENDNG != status
    update_attribute(:status, STATUS_PROCESSING)
    # convert to flv
    flv_path = "#{AppConfig.tmp_dir}/video-#{id}.flv"
    File.delete flv_path if File.exists? flv_path

    # get an image from the video after 4 seconds 
    img_path = "#{AppConfig.tmp_dir}/video-#{id}-%d.jpg"
    img_path2 = "#{AppConfig.tmp_dir}/video-#{id}-1.jpg"
    File.delete img_path2 if File.exists? img_path2

    begin
      system("#{AppConfig.video_conversion_command} -i #{File.expand_path(RAILS_ROOT)}/#{original_file} -ar 44100 #{flv_path}")
      raise "Failed to convert '#{File.expand_path(RAILS_ROOT)}/#{original_file}' to flv!" unless $? == 0
      self.stream_file = File.new(flv_path)
      if image.blank?
        system("#{AppConfig.video_conversion_command} -i #{File.expand_path(RAILS_ROOT)}/#{original_file} -an -ss 00:00:04 -an -r 1 -vframes 1 -y #{img_path}")
        unless File.exists? img_path2
          system("#{AppConfig.video_conversion_command} -i #{File.expand_path(RAILS_ROOT)}/#{original_file} -an -ss 00:00:00 -an -r 1 -vframes 1 -y #{img_path}")
        end
        p "tmp img - #{img_path2}"
        self.image = File.new(img_path2) if File.exists? img_path2
      end

      self.status = STATUS_LIVE
      self.save!
      watermark_image("#{RAILS_ROOT}/#{image('thumb')}") unless image.blank?
      FileUtils.rm_rf(self.original_file_dir)
      return true
    rescue
      update_attribute(:status, STATUS_ERROR)
      logger.error "ERROR:#{Time.now.iso8601}: #{$!}"
      return false
    ensure
      File.delete flv_path if File.exists? flv_path
      File.delete img_path2 if File.exists? img_path2
    end
  end

  def streaming_path
    "/uploads/video/stream_file/#{stream_file_relative_path}"
  end

  def image_path(size = nil)
    "/uploads/video/image/#{image_relative_path(size)}"
  end

  def converted?
    status == STATUS_LIVE
  end

  # Gets the apprx minutes left to convert this video into flv 
  def time_to_conversion
    converted? ? -1 : 10 - (Time.now.min % 10) # assumes a cron job runs every 10 minutes
  end

  def self.upload_to_s3(limit = 1000)
    move_all_images_to_s3(:conditions => ['image is not null and image_in_s3 = ? and status = ?', false, STATUS_LIVE], :limit => limit, :order => 'updated_on desc')
    msg = move_all_stream_files_to_s3(:conditions => ['stream_file is not null and stream_file_in_s3 = ? and status = ?', false, STATUS_LIVE], :limit => limit, :order => 'updated_on desc')
  end

  def self.move_images(path_to_uploads_folder)
    total_files = count(:conditions => 'image is not null')
    start_time = Time.now
    p "Moving #{total_files} files..."
    find(:all, :conditions => 'image is not null').each_with_index do |q, i|
      if File.exists?("#{path_to_uploads_folder}/video/image/#{q.image_relative_path('medium')}")
        FileUtils.mv("#{path_to_uploads_folder}/video/image/#{q.image_relative_path('medium')}", "#{path_to_uploads_folder}/video/image/#{q.image_relative_path}")
        FileUtils.remove_dir("#{path_to_uploads_folder}/video/image/#{q.image_relative_dir}/medium")
        FileUtils.remove_dir("#{path_to_uploads_folder}/video/image/#{q.image_relative_dir}/large")
      else
        p "not found #{path_to_uploads_folder}/video/image/#{q.image_relative_path('medium')}"
      end
      p "Completed #{i} of #{total_files} (#{(i.to_f * 100.0/total_files.to_f).round_to(2)}%)" if i % 100 == 0
    end
    return "Moved #{total_files} files in #{Time.now - start_time} seconds"
  end

  private
  def watermark_image(img_path)
    dst = Magick::Image.read(img_path).first
    src = Magick::Image.read("#{RAILS_ROOT}/public/images/video.gif").first

    result = dst.composite(src, Magick::CenterGravity, Magick::OverCompositeOp)
    result.write(img_path)
  end

end
