require File.dirname(__FILE__) + '/../test_helper'

class OldC2wUserTest < Test::Unit::TestCase
  fixtures :old_c2w_users

  # Replace this with your real tests.
  def test_find_old
    assert OldC2wUser.find_old(old_c2w_users(:jim).userid)
    assert OldC2wUser.find_old(old_c2w_users(:jim).email)
    assert OldC2wUser.find_old(old_c2w_users(:jim).email+'t').nil?
  end
end
