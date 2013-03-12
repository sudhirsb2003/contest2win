require File.dirname(__FILE__) + '/../test_helper'

class CrosswordQuestionTest < Test::Unit::TestCase

  def test_answer
    c = CrosswordQuestion.new(:answer => 'Nikhil Gupte')
    assert_equal 'NIKHILGUPTE', c.answer

    c = CrosswordQuestion.new(:answer => "ABc's -Def12 3 * & %")
    assert_equal 'ABCSDEF123', c.answer
  end

end
