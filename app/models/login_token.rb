#-- $Id: login_token.rb 87 2007-02-17 23:06:39Z ngupte $ ++#
# LoginTokens are used to bypass regular password based authentication which is required
# when a user has forgotten it's password.
class LoginToken < ActiveRecord::Base

  belongs_to :user

  # Generate a new token for the given user. 
  def self.generate(user)
    LoginToken.create(:user => user, :token => random_token(20))
  end

  def self.random_token(size=18)
    ActiveSupport::SecureRandom.hex(size)
    #chars = ("a".."z").to_a + ("1".."9").to_a 
    #newpass = Array.new(size, '').collect{chars[rand(chars.size)]}.join
  end
end
