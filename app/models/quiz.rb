#-- $Id: quiz.rb 2143 2008-07-17 07:53:11Z ngupte $
#++
# A Quiz is a type of <tt>Contest</tt> which has questions each with multiple options,
# of varying points.
# The correct option usually has one point.
class Quiz < Contest

  has_many :classifications, :foreign_key => :contest_id, :order => 'maximum_score desc'
  
end
