require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :users, :contests, :messages 

  def test_deletable
    assert messages(:one).deletable?(messages(:one).sender), "sender can delete" 
    assert messages(:one).deletable?(messages(:one).receiver), "receiver can delete"
    assert messages(:one).deletable?(users(:a_moderator)), "a moderator can delete"
    assert ! messages(:one).deletable?(users(:user4)), "some other user cannot delete"
  end
end
