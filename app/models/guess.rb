class Guess < ActiveRecord::Base

	belongs_to :question
	belongs_to :response

    before_create :evaluate
    validates_presence_of :value
    validates_size_of :value, :maximum => 1, :allow_nil => true

    def to_xml(options ={})
      super(:skip_types => true, :only => [:value, :correct]) do |xml|
        xml.tag!('fill-in-the-blanks', question.fill_in_the_blanks(response.guesses_as_string(question_id)))
        xml.tag!('points-available', response.possible_score(question_id))
      end
    end

    private
	# evaluates the correctness of this attempt.
	def evaluate
        #if self.value.nil?
          #self.value = ''
        #else  
          self.value = self.value.upcase
        #end  
		self.correct = !question.answer.upcase.index(value).nil?
        true
	end
end
