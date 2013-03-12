#-- $Id: bulk_importer.rb 2206 2008-09-08 16:29:35Z ngupte $
#++
# 
# The BulkImporter accepts a single CSV file OR a zip file containing a <tt>contest.csv</tt> file and possibly images
# in the case of an image based contest, and creates the conetst in one single operation.
# Only <tt>Poll</tt>s and <tt>Quiz</tt>zes can be bulk imported. The <tt>conetst.csv</tt> file should have the
# following columns:
#   * Serial No - 1...N
#   * Question - The question
#   * Option 1..N - (where N <= 5)
#   * Points 1..N - Points to award for the corresponding option. Points columsn are not needed in the case of Polls.
# For image based contests, an image with the name corresponding to the <tt>Serial No</tt> must be present in the
# zip archive.
# 

require 'fastercsv'

class BulkImporter
  @@tmp_dir = AppConfig.tmp_dir

  def  self.tmp_dir
    @@tmp_dir
  end

  def self.extract(zip_file, contest) 
    #logger = RAILS_DEFAULT_LOGGER
    if zip_file.is_a?(String)
        contest.errors.add(nil, 'Please specify a ZIP/CSV file.')
        return contest
    end  
    if zip_file.is_a?(Tempfile)
      zip_file_path = zip_file.path
    else
      zip_file_path = "#{@@tmp_dir}/#{contest.user.username}-#{Time.now.to_i}-file"
      File.open(zip_file_path, "wb") { |f| f.write(zip_file.read) }
    end  
    begin
    extract_to = "#{@@tmp_dir}/#{contest.user.username}-#{Time.now.to_i}"
    #if (zip_file.content_type.index('zip'))
    if (zip_file.original_filename.downcase.index('zip'))
      unless system( "/usr/bin/unzip #{zip_file_path} -d #{extract_to}")
        contest.errors.add(nil, 'Could not extract contents from the uploaded file. Was it a proper zip file?')
        return contest
      end
      csv_file_path = "#{extract_to}/contest.csv"
    #elsif zip_file.content_type.index('csv') || zip_file.content_type.index('comma')
    elsif zip_file.original_filename.downcase.index('csv')
        csv_file_path = zip_file_path
    else
        contest.errors.add(nil, "Unknown file format - #{zip_file.content_type}. Sorry, I can only handle <tt>zip</tt> and <tt>csv</tt> files.")
        return contest
    end  
    unless File.exists?(csv_file_path)
      contest.errors.add(nil, 'Could not find <tt>contest.csv</tt> file inside the uploaded zip file.')
      return contest
    end  
    questions = []
    @data = FasterCSV.table(csv_file_path, {:skip_blanks => true})
    @data.each_with_index do |row, j|
      if row[:question].nil? || row[:question].to_s.empty? || row[:question] == 0
        next
      end
      question = Question.new(:question => row[:question])
      question.contest = contest
      question.user = contest.user
      question.status = Question::STATUS_LIVE
      if Contest::CONTENT_TYPE_IMAGE == contest.content_type
        unless row[:serial_no]
          contest.errors.add(:serial_no, "not found, line##{j+1}")
          next
        end
        file_path = try_file_types("#{extract_to}/#{row[:serial_no]}")
        if file_path
          question.image = File.new(file_path, 'r')
        else
          contest.errors.add(:image, " not found for question# #{row[:serial_no]}")
          next
        end  
      end  
      5.times do |index| # read options
        i = index + 1
        if row["option_#{i}".to_sym]
          option = QuestionOption.new(:text => row["option_#{i}".to_sym].to_s, :position => i)
          if contest.is_a? Quiz
            unless row["points_#{i}".to_sym]
              contest.errors.add_to_base("Points not specified for option# #{i} of question# #{row[:serial_no]}")
              next
            end  
            option.points = row["points_#{i}".to_sym]
          end      
          question.options << option
        else
          break
        end
      end # read options
      unless question.save
        contest.errors.add(nil, " #{question.errors.full_messages.to_sentence} for question# #{row[:serial_no]}")
      end
    end
	rescue Exception => err
        logger.error(err.to_s)
        raise err
    ensure
      File.delete(zip_file_path)
      FileUtils.rm_rf(extract_to)
    end
    contest
  end

  def self.try_file_types(file_path)
    return file_path+'.jpg' if File.exists?(file_path+'.jpg')
    return file_path+'.JPG' if File.exists?(file_path+'.JPG')
    return file_path+'.gif' if File.exists?(file_path+'.gif')
    return file_path+'.GIF' if File.exists?(file_path+'.GIF')
    return file_path+'.png' if File.exists?(file_path+'.png')
    return file_path+'.PNG' if File.exists?(file_path+'.PNG')
    return nil
  end
end

