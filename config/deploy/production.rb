set :branch, "production"
set :host, "ec201.c2w.com"

role :web, host
role :db, host, :primary => true
role :app, host
