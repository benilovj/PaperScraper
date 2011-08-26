require 'bundler/setup'

require 'logger'
require 'active_record'
require 'fileutils'

$: << File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

RAILS_ENV = ENV['RAILS_ENV'] || 'development'
dbconf = YAML::load(File.open('config/databases.yml'))[RAILS_ENV]
ActiveRecord::Base.establish_connection(dbconf)

FileUtils.mkdir('log') unless Dir.exists?('log')
ActiveRecord::Base.logger = Logger.new(File.open('log/database.log', 'a'))