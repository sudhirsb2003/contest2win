class CrosswordQuestion < Question
  include CrosswordsHelper

  has_one :clue, :class_name => 'CrosswordClue', :foreign_key => 'question_id'
  validates_size_of :answer, :maximum => 15, :allow_nil => true

  validates_presence_of :answer

   def answer=(a)
    a = a.gsub(/\W/,'').upcase
    options.delete_all
    option = options.build(:text => a)
    option.points = 1
  end

  def before_validation
    if self.image.blank?
      self.content_type = Contest::CONTENT_TYPE_TEXT
    else
      self.content_type = Contest::CONTENT_TYPE_IMAGE
    end
  end
	
end
