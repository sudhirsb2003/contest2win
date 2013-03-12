# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.11' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'hash_helper'
require 'auditable'
require 'plugins/file_column/lib/s3_file_column'

#require 'plugins/app_config/lib/configuration'

@@memcache_options = {
  :compression => false,
  :debug => false,
  :namespace => 'c2w',
  :readonly => false,
  :urlencode => false
}
@@memcache_servers = [ 'localhost' ]

Rails::Initializer.run do |config|
  config.action_controller.session = {
    :key => '_c2w_session-2.28',
    :secret      => '8cff727809e989488c5a1bee2a04028c7f88d4d38b8cc7dba9cd98f3b13e2070ca6f6334693a0ebab79e27fce7346b8645599815610575c7fa056829e9b9eca8',
  }

  #config.gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate', :source => 'http://gems.github.com'
  #config.gem 'htmlentities'
  #config.gem 'koala'
  #config.gem 'right_aws'
  #config.gem 'calendar_date_select'
  #config.gem 'json' # causes weird errors in to_json({})
  #  config.gem 'RedCloth', :version => '3.0.4'

  #config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
  #File.directory?(lib = "#{dir}/lib") ? lib : dir
  #end

  config.action_controller.cache_store = [:mem_cache_store, @@memcache_servers, @@memcache_options]
  #custom config has been moved to config/app_config.yml
  config.action_mailer.delivery_method = :smtp

  # these options are only needed if you choose smtp delivery
  config.action_mailer.smtp_settings = {
    #:enable_starttls_auto => true,
    #:tls => true,
    :port => 587,
    :domain => "c2w.com",
    :authentication => :plain,
    :address => "smtp.sendgrid.net",
    :user_name => 'c2wsendgrid',
    :password => 'c2w@123'
  }
end
#require 'will_paginate'

ActiveRecord::Base.send :include, Auditable::Acts::Audited
FileColumn::S3FileColumnExtension::Config.s3_access_key_id = Setting.value(:s3_access_key_id)
FileColumn::S3FileColumnExtension::Config.s3_secret_access_key = Setting.value(:s3_secret_access_key)
FileColumn::S3FileColumnExtension::Config.s3_bucket_name = Setting.value(:s3_bucket_name)
FileColumn::S3FileColumnExtension::Config.s3_distribution_url = Setting.value(:s3_distribution_url)

# create a tmp directory
FileUtils.mkdir_p(BulkImporter.tmp_dir)

class String
	def each_word(&block)
		self.split(/ /).each {|w| block.call(w) }
	end
end

class Time
  # Convineince method to get the end-of-day value for a date.
  # This comes in handy when doing date ranges where the end date implies
  # till the last second of the end date. 
  def eod
    self.to_time.midnight + 1.day - 1.second
  end
end

module Math
  def self.log2(n)
    log(n)/log(2)
  end
end

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

ENV['RECAPTCHA_PUBLIC_KEY'] = '6Le_6AQAAAAAAK_arI8hAk0e8jNZudmYsMgkyQnX'
ENV['RECAPTCHA_PRIVATE_KEY'] = '6Le_6AQAAAAAAKhtoH6AH90282008Ejw1Xgww0tl'

#C2W::Config::safe_mode = true

CalendarDateSelect::FORMATS[:indian] = {
  # Here's the code to pass to Date#strftime
  :date => "%d/%m/%Y",
  :time => " %H:%M",

  :javascript_include => "format_indian"
}
CalendarDateSelect.format = :indian
