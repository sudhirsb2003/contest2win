require File.dirname(__FILE__) + '/../test_helper'
require 'hangman_controller'
require 'user'
require 'question'

# Re-raise errors caught by the controller.
class HangmanController; def rescue_action(e) raise e end; end

class HangmanControllerTest < Test::Unit::TestCase
  fixtures :users, :contests

  def setup
    @controller = HangmanController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Check for validations...
  def test_validations
    contest = {:title => '', :tag_list => '',
      :description => 'test',
      'starts_on(1i)' => Time.new.year.to_s, 'starts_on(2i)' => '12', 'starts_on(3i)' => '31',
      'ends_on(1i)' => (Time.new.year + 1).to_s, 'ends_on(2i)' => '2', 'ends_on(3i)' => '31', :category_id => 1
      }
    post :new, {:contest => contest}, {:user => users(:an_admin) }
    assert_equal 3, assigns['contest'].errors.size
    assert_equal "can't be blank", assigns['contest'].errors.on(:title)
    assert_equal "can't be blank", assigns['contest'].errors.on(:tag_list)
    assert_equal "is an invalid date", assigns['contest'].errors.on(:ends_on)
  end

  def test_create_never_ending
    contest = {:title => 'test', :tag_list => 'test',
      :description => 'test', 'starts_on(1i)' => Time.new.year.to_s, 'starts_on(2i)' => '12', 'starts_on(3i)' => '31',
      :never_ends => 'true', :category_id => 1
      }
    post :new, {:contest => contest}, {:user => users(:a_user) }
    assert assigns['contest'].id
  end

end
