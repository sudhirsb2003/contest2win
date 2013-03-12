class AdAccount < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :publisher_id
  validates_size_of :publisher_id, :channel_id, :maximum => 100, :allow_nil => true

  def before_save
    self.publisher_id.strip!
    self.channel_id.strip!
  end
end
