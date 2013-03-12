require File.dirname(__FILE__) + '/../test_helper'

class EntryTest < Test::Unit::TestCase
  fixtures :users, :contests, :entries 

  def test_deletable
    assert entries(:live).deletable?(entries(:live).user), "Submitter can delete" 
    assert entries(:live).deletable?(entries(:live).faceoff.user), "Creator of the F/O can delete"
    assert entries(:live).deletable?(users(:a_moderator)), "a moderator can delete"
    assert ! entries(:live).deletable?(users(:user4)), "some other user cannot delete"
  end

  def test_editable_live
    assert ! entries(:live).editable?(entries(:live).user), "Submitter cannot edit" 
    assert ! entries(:live).editable?(entries(:live).faceoff.user), "Creator of the F/O cannot edit"
    assert entries(:live).editable?(users(:a_moderator)), "a moderator can edit"
    assert ! entries(:live).editable?(users(:user4)), "some other user cannot edit"
  end

  def test_editable_pending
    assert entries(:draft).editable?(entries(:draft).user), "Submitter can edit draft" 
    assert !entries(:pending).editable?(entries(:pending).user), "Submitter cannot edit if approval is pending" 
    assert ! entries(:pending).editable?(entries(:pending).faceoff.user), "Creator of the F/O cannot edit"
    assert entries(:pending).editable?(users(:a_moderator)), "a moderator can edit"
    assert ! entries(:pending).editable?(users(:user4)), "some other user cannot edit"
  end

end
