#-- $Id: classification.rb 288 2007-08-19 20:13:58Z ngupte $ ++
#
# <tt>Contest</tt>s may have several Classifications based on the score.
# Example:
#   < 1000 - You looser, get the hell outta here!
#   > 1000 < 2000 - You can do better...
#   > 2000 - Grreat! You can turn pro now!
class Classification < ActiveRecord::Base

  belongs_to :contest

  validates_presence_of :minimum_score, :maximum_score, :description
  validates_numericality_of :minimum_score, :maximum_score
end
