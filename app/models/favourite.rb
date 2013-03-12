class Favourite < ActiveRecord::Base
  belongs_to :user, :foreign_key => :user_id
  belongs_to :contest, :counter_cache => 'favourited'
end
