#-- $Id: friendship.rb 2193 2008-09-08 11:57:47Z ngupte $
#++
#
# Friendships are a mapping between a user <tt>user_id</tt> and her friend <tt>friend_id</tt>
# 
class Friendship < ActiveRecord::Base
  belongs_to :user, :foreign_key => :user_id, :counter_cache => :number_of_friends
  belongs_to :friend, :foreign_key => :friend_id
end
