require File.dirname(__FILE__) + '/../test_helper'

class VideoTest < Test::Unit::TestCase
  #fixtures :videos

  def test_generate_stream_file
    video_file = File.new "#{File.expand_path(RAILS_ROOT)}/test/fixtures/videos/test.mov"
    p video_file.path
    video = Video.create!(:title => 'Test avi', :created_by_id => 1, :original_file => video_file)
    assert_nil video.image
    assert_nil video.stream_file
    assert Video::STATUS_CONVERSION_PENDNG, video.status
    assert video.convert
    video.reload
    assert Video::STATUS_LIVE, video.status
    assert_not_nil video.stream_file
    assert File.exists? video.stream_file
    assert_not_nil video.image
    assert File.exists? video.image
  end

  def test_generate_stream_file_of_an_invalid_file
    video_file = File.new "#{File.expand_path(RAILS_ROOT)}/test/fixtures/videos/invalid.avi"
    video = Video.create!(:title => 'Test avi', :created_by_id => 1, :original_file => video_file)
    assert_nil video.image
    assert_nil video.stream_file
    assert Video::STATUS_CONVERSION_PENDNG, video.status
    assert !video.convert
    video.reload
    assert Video::STATUS_ERROR, video.status
    assert_nil video.stream_file
    assert_nil video.image
  end
end
