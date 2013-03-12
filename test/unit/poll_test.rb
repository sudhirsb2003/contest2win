require File.dirname(__FILE__) + '/../test_helper'

class PollTest < Test::Unit::TestCase
#  fixtures :users

  # Replace this with your real tests.
  def test_create_with_correct_attributes
    @poll = Poll.new({:title => 'test poll', :description => 'blah blah...', :category_id => 1,
        :tag_list => 'test, automated', :ends_on => Date.today + 10.days})
    @poll.user_id = 1
    @poll.save
    @poll.errors.each {|k,v| p "#{k}:#{v}"}
    assert @poll.errors.empty?
  end

  def test_create_with_incorrect_dates
    @poll = Poll.new({:title => 'test poll', :description => 'blah blah...', :category_id => 1,
        :tag_list => 'test, automated', :starts_on => Date.today + 11.days, :ends_on => Date.today + 10.days})
    @poll.user_id = 1
    @poll.save
    assert 'Ends on cannot be before Starts on!', @poll.errors.full_messages.first
    assert_equal 1, @poll.errors.size
  end
end
