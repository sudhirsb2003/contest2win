require File.dirname(__FILE__) + '/../test_helper'

class PersonalityTestTest < Test::Unit::TestCase
  fixtures :users, :contests, :contest_regions, :regions, :personalities

  def test_personality_for_score
    assert_equal 'A', contests(:personality_test_1).personality_for_score(0).title
    assert_equal 'A', contests(:personality_test_1).personality_for_score(1).title
    assert_equal 'A', contests(:personality_test_1).personality_for_score(3).title
    assert_equal 'B', contests(:personality_test_1).personality_for_score(4).title
    assert_equal 'B', contests(:personality_test_1).personality_for_score(7).title
    assert_nil contests(:personality_test_1).personality_for_score(17)
  end

end
