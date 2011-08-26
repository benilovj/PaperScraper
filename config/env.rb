require 'bundler/setup'

require 'logger'
require 'active_record'
require 'fileutils'

BASE_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..')

$: << File.join(BASE_PATH, 'lib')

RAILS_ENV = ENV['RAILS_ENV'] || 'development'
dbconf = YAML::load(File.open('config/databases.yml'))[RAILS_ENV]
ActiveRecord::Base.establish_connection(dbconf)

LOG_PATH = File.join(BASE_PATH, 'log')
FileUtils.mkdir(LOG_PATH) unless File.directory?(LOG_PATH)
ActiveRecord::Base.logger = Logger.new(File.open(File.join(LOG_PATH, 'database.log'), 'a'))