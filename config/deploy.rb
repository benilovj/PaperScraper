require "bundler/capistrano"

default_run_options[:pty] = true

set :default_environment, {
  'PATH' => "$HOME/.gems/bin:$PATH"
}

set :user, 'ricm'
set :domain, 'mailorguardian.ricm.com'
set :application, 'mailorguardian'

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
  
  desc "Create a symlink from the production SQLite DB to the current release"
  task :setup_db do
    run "ln -s #{shared_path}/db/papers.sqlite #{release_path}/papers.sqlite"
  end  
end

namespace :rake do  
  desc "Run a task on a remote server: cap rake:invoke task=a_certain_task"  
  task :invoke do  
    run "cd #{deploy_to}/current; bundle exec rake #{ENV['task']} RAILS_ENV=#{rails_env}"
  end  
end

after "deploy:setup_db", "deploy:migrate"