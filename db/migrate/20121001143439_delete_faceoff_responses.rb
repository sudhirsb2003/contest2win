class DeleteFaceoffResponses < ActiveRecord::Migration
  def self.up
    execute %Q{delete from responses where type in ('FaceoffResponse', 'RateMeResponse') }
  end

  def self.down
  end
end
