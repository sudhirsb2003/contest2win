class AddContentTypeToQuestion < ActiveRecord::Migration
  def self.up
  	add_column :questions, :content_type, :string
  	Question.find(:all).each {|q|
		q.update_attribute(:content_type, q.contest.content_type)	
	}
  end

  def self.down
  	remove_column :questions, :content_type
  end
end
