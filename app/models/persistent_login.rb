class PersistentLogin < ActiveRecord::Base
  belongs_to :user
  before_create :assign_uid
  
  private
  
  def assign_uid
    self.uid = UUID.create_random.to_s
    #self.uid = SecureRandom.base64(32)
  end
end
