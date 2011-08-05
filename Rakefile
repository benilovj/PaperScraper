require 'bundler/setup'

$: << File.expand_path(File.dirname(__FILE__))

require 'rspec/core/rake_task'

task :configuration do
  require 'yaml'
  @config = YAML.load_file('config/databases.yml')[ENVIRONMENT]

  require 'PaperScraper'
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

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
  t.verbose = false
end

namespace :scraper do
  task :cap_number_of_comments => :configuration do
    puts "Table status: #{Comment.guardian.count} Guardian comments. #{Comment.mail.count} Daily Mail comments."
    puts "Capping the maximum amount of comments..."
    Comment.keep_only_latest_comments
    puts "Table status: #{Comment.guardian.count} Guardian comments. #{Comment.mail.count} Daily Mail comments."
  end
  
  task :run_scrape => :configuration do
    puts "Scraping began at #{Time.now}..."
    mail_comment_count = Comment.mail.count
    guardian_comment_count = Comment.guardian.count
    case
    when guardian_comment_count > mail_comment_count + 20 then
      prescription = PAPERS.select {|paper| paper.name == "Mail"}
    when mail_comment_count > guardian_comment_count + 20 then
      prescription = PAPERS.select {|paper| paper.name == "Guardian"}
    else 
      prescription = PAPERS
    end
    
    prescription.each(&:scrape_next_unconsumed_article_if_exists)
    puts "Scraping complete at #{Time.now}"
  end
  
  task :replenish_article_lists => :configuration do
    puts "Started replenishing article lists at #{Time.now}"
    PAPERS.select(&:time_to_replenish?).each(&:replenish_article_urls)
  end
  
  desc "Downloads the comments from articles"
  task :execute => [:cap_number_of_comments, :run_scrape]

  desc "Updates the list of articles"
  task :maintain => [:replenish_article_lists, :cap_number_of_comments]
end