class UserPreference < ActiveRecord::Base
  PREFERENCE_TYPES = {:no_mail_on_comment => 10, :no_mail_on_message => 20, :no_newsletter => 30, :no_stats_newsletter => 40}

  belongs_to :user
end
