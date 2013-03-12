set :branch, "master"
set :host, "staging.c2w.com"

role :web, host
role :db, host, :primary => true
role :app, host
set :rails_env, "staging"
