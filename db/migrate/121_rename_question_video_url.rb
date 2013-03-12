class RenameQuestionVideoUrl < ActiveRecord::Migration
  def self.up
    execute %{ALTER table questions rename column video_url to external_video_url}
  end

  def self.down
    execute %{ALTER table questions rename column external_video_url to video_url}
  end
end
