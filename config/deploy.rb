require "bundler/capistrano"

default_run_options[:pty] = true

# be sure to change these
set :user, 'ricm'
set :domain, 'mailorguardian.ricm.com'
set :application, 'mailorguardian'

# the rest should be good
set :repository,  "git@github.com:benilovj/PaperScraper.git"
set :deploy_to, "/home/#{user}/#{domain}"
set :deploy_via, :remote_cache
set :scm, 'git'
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
set :use_sudo, false

server domain, :app, :web
role :db, domain, :primary => true

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end