require File.dirname(__FILE__) + '/../test_helper'

class SkinTest < Test::Unit::TestCase
  fixtures :skins, :users, :contests

  def test_quiz_skins_for_admin
    assert_equal 2, Skin.find_by_type('Quiz', users(:an_admin)).size
  end

  def test_quiz_skins_for_everyone
    assert_equal 1, Skin.find_by_type('Quiz', users(:a_user)).size
  end
end
