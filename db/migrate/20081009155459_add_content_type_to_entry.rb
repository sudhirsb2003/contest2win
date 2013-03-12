class AddContentTypeToEntry < ActiveRecord::Migration
  def self.up
    add_column :entries, :content_type, :string
    Entry.update_all "content_type = 'Image'", 'image is not null'
    Entry.update_all "content_type = 'Video'", 'video_id is not null'
  end

  def self.down
    remove_column :entries, :content_type
  end
end
