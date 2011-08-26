require 'bundler/setup'

$: << File.expand_path(File.dirname(__FILE__))

task :configuration do
  require 'yaml'
  require 'PaperScraper'
  @config = YAML.load_file('config/databases.yml')[RAILS_ENV]
end

namespace :db do  
  task :configure_connection => :configuration do
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
  end
  
  desc 'Migrate the database (options: VERSION=x).'
  task :migrate => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate 'db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end
end

namespace :scraper do
  task :cap_number_of_comments => :configuration do
    puts PAPERS.status
    puts "Capping the maximum amount of comments..."
    Comment.keep_only_latest_comments
    puts PAPERS.status
  end
  
  task :run_scrape => :configuration do
    puts "Scraping began at #{Time.now}..."
    PAPERS.run_scrape
    puts "Scraping complete at #{Time.now}"
  end
  
  task :replenish_article_lists => :configuration do
    puts "Started replenishing article lists at #{Time.now}"
    PAPERS.replenish
  end
  
  desc "Downloads the comments from articles"
  task :execute => [:cap_number_of_comments, :run_scrape]

  desc "Updates the list of articles"
  task :maintain => [:replenish_article_lists, :cap_number_of_comments]
end

unless ENV['RAILS_ENV'] == 'production'
  require 'rspec/core/rake_task'
  
  desc "Run all examples"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w[--color]
    t.verbose = false
  end
end