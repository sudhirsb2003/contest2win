#-- $Id: quiz.rb 2143 2008-07-17 07:53:11Z ngupte $
#++
# A PersonalityTest is a type of <tt>Contest</tt> which has questions each with multiple options,
# of varying points and users are classified on the basis of their final scores.
class PersonalityTest < Contest

  has_many :personalities, :foreign_key => :contest_id, :order => 'minimum_score asc'

  def personality_for_score(score)
    personalities.find(:first, :conditions => ['minimum_score <= ? and maximum_score >= ?', score, score])
  end

  def show_others_can_add_option?() return false end

  def personality_addable?(user)
    return self.user == user || (user && user.admin?)
  end

  def scorable?() false end
end
