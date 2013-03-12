class CreatePrizes < ActiveRecord::Migration
  def self.up
    create_table :prizes do |t|
      t.column "title",                     :string,   :limit => 100,                       :null => false
      t.column "description",               :string,                                        :null => false
      t.column "video_url",       :string
      t.column "image",       :string
      t.column "disabled",                :boolean,                                      :null => false, :default => false
      t.column "created_on",                :datetime,                                      :null => false
      t.column "updated_on",                :datetime,                                      :null => false
    end
  end

  def self.down
    drop_table :prizes
  end
end
