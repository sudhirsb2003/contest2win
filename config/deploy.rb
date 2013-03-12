set :stages, %w(production staging)
require 'capistrano/ext/multistage'
require 'bundler/capistrano'

set :application, "c2w"
set :repository, "git@github.com:githubc2w/C2W-Portal.git"
set :scm, :git

ssh_options[:forward_agent] = true
set :deploy_via, :remote_cache
set :deploy_to, "/var/www/apps/c2w"
set :user, "c2w"
set :use_sudo, false

set :tag_on_deploy, true
set :build_gems, false
set :compress_assets, false
set :backup_database_before_migrations, false
set :keep_releases, 5

set :bundle_without, [:development, :test, :cucumber]
set :bundle_flags,   "--deployment"

set :default_environment, { 'PATH' => "/usr/local/bin:$PATH" }

default_run_options[:pty] = true

after "deploy:update_code", "deploy:link_config", "deploy:symlink_assets"
#after "deploy:symlink", "deploy:update_crontab"

set :config_files, %w(database.yml)
namespace :deploy do
  desc 'symlink config files'
  task :link_config, :roles => :app do
    unless config_files.empty?
      config_files.each do |file|
        run "ln -nsf #{File.join(shared_path, "config/" + file)} #{File.join(release_path, "/config/" + file)}"
      end
    end
  end
  
  desc "Update the crontab file"
  task :update_crontab, :roles => [:jobs] do
    run "cd #{release_path} && bundle exec whenever --update-crontab #{application} --set environment=#{rails_env}"
  end

#  task :after_setup do
#    run "mkdir #{shared_path}/uploads"
#    run "mkdir #{shared_path}/static"
#  end

  task :symlink_assets do
    run <<-CMD
      ln -s #{shared_path}/uploads #{current_release}/public/uploads &&
      ln -s #{shared_path}/static #{current_release}/public/static
    CMD
  end

  task :restart do
    run <<-CMD
     touch #{current_path}/tmp/restart.txt
    CMD
  end
end
