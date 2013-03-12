ActionController::Routing::Routes.draw do |map|
  map.home '/', :controller => 'home'
  map.home '/start', :controller => 'home'
  map.home2 '/home/:action', :controller => 'home'
  map.search '/search', :controller => 'home', :action => 'search'
  map.change_region '/chr/:region', :controller => 'home', :action => 'change_region'
  map.contact_us '/contact_us', :controller => 'home', :action => 'contact_us'
  map.play ':id/:action', :controller => 'contests', :action => :redirect_to_play, :requirements => {:id => /\d+/}

  map.import_contacts 'import_contacts/:action', :controller => 'import_contacts', :action => :index

  map.namespace :admin do |admin|
    admin.resources :campaigns
  end

  # Moderation
  map.contest_moderation 'admin/contests/:action/:id', :controller => 'admin/contests'
  map.user_moderation 'admin/users/:action/:id', :controller => 'admin/users'

  map.account_management 'admin/accounts/:action/:id', :controller => 'admin/accounts', :action => :list
  map.category_management 'admin/categories/:action/:id', :controller => 'admin/categories', :action => :list
  map.bulk_upload 'admin/bulk_upload/:action/:id', :controller => 'admin/bulk_upload'
  map.prize_categories_management 'admin/prize_categories/:action/:id', :controller => 'admin/prize_categories', :action => :list
  map.prizes_management 'admin/prizes/:action/:id', :controller => 'admin/prizes', :action => :list
  map.skins_management 'admin/skins/:action/:id', :controller => 'admin/skins', :action => :list
  map.brands_management 'admin/brands/:action/:id', :controller => 'admin/brands', :action => :list
  map.admin 'admin/:action/:id', :controller => 'admin'

  # facebook actions
  map.facebook 'facebook/:action', :controller => 'facebook'

  # user's account
  map.account 'account/:action', :controller => 'account', :action => 'index'

  # users
  map.user 'users/:username/:action', :controller => 'users', :action => :profile
  map.community 'community/:action', :controller => 'community', :action => :summary

  # prizes
  map.prizes 'prizes/:action/:id', :controller => 'prizes', :action => 'browse', :id => nil

  map.leaderboard 'leaderboards/:duration', :controller => 'leaderboards', :action => 'show', :duration => 'daily'

  map.personalities 'personalities/:id/:action.:format', :controller => 'personalities', :action => :badge
  map.personalities 'personalities/:id/:action', :controller => 'personalities', :action => :badge

  # contests
  map.contest ':controller/:id/:action.:format', :action => 'play', :requirements => {:id => /\d+\-[^\/]*/}
  map.contest ':controller/:id/:action', :action => 'play', :requirements => {:id => /\d+\-[^\/]*/}

  map.contests ':controller/:action/:page.:format', :requirements => {:page => /\d+/}
  map.contests ':controller/:action', :requirements => {:controller => /contests|hangman|quizzes|crosswords|personality_tests/}
  #map.contests ':controller/:action', :requirements => {:controller => /contests|hangman|quizzes|crosswords|personality_tests|faceoffs|predictions|rate_me|twisters/}

  map.contest_api ':controller/:id/x/:action.:format', :action => 'play', :requirements => {:id => /\d+/}

  map.category_shortcuts '/:slug', :controller => 'categories', :action => :show

  # Install the default route as the lowest priority.
  #map.connect ':controller/:action.:format'
  #map.connect ':controller/:action/:id'

  map.comatose_wcms 'pg/:region/:page', :controller => 'home'
end
