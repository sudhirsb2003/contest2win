class Vote < ActiveRecord::Base
  belongs_to :contest, :counter_cache => 'net_votes', :foreign_key => 'voteable_id'
end
