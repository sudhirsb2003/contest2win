class FixQuestionContentTypes < ActiveRecord::Migration
  def self.up
    Question.update_all "content_type = 'YTVideo'", "external_video_url is not null and external_video_url != '' and content_type != 'YTVideo'"
  end

  def self.down
  end
end
