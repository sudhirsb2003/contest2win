ActiveRecord::Base.send :include, Auditable::Acts::Audited # added cos there was an error while loading related to acts_as_auditable

# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_controller.page_cache_directory = RAILS_ROOT + "/public/cache/"

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
config.action_mailer.raise_delivery_errors = true
#config.action_mailer.server_settings = {:address => '64.151.72.13', :username => 'mail.c2w.com', :password => 'mail'}

config.log_level = :warn

#config.action_view.cache_template_loading = true

#custom config has been moved to config/environments/production.yml
config.action_controller.session.update(:session_domain => 'c2w.com')
