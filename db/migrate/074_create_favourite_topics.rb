require 'migration_helpers'

class CreateFavouriteTopics < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :favourite_topics do |t|
      t.column "name", :string,   :limit => 30, :null => false, :unique => true
    end

    create_table :favourite_topics_users, :id => false do |t|
      t.column 'favourite_topic_id', :integer, :null => false
      t.column 'user_id', :integer, :null => false
    end
    add_index :favourite_topics_users, [:favourite_topic_id]
    add_index :favourite_topics_users, [:user_id]
    foreign_key(:favourite_topics_users, :user_id, :users)
    foreign_key(:favourite_topics_users, :favourite_topic_id, :favourite_topics)
    #['Movies','Music','Trivia','Gadgets','Technology','Cars','Sports','Politics'].each {|t|
    #    FavouriteTopic.create(:name => t)
    #}


  end

  def self.down
    drop_table :favourite_topics_users
    drop_table :favourite_topics
  end
end
