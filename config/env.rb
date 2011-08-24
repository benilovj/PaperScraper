require 'bundler/setup'

require 'logger'
require 'active_record'
require 'fileutils'

BASE_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..')

$: << File.join(BASE_PATH, 'lib')

ENVIRONMENT = ENV['ENVIRONMENT'] || 'development'
dbconf = YAML::load(File.open('config/databases.yml'))[ENVIRONMENT]
ActiveRecord::Base.establish_connection(dbconf)

if ENVIRONMENT == 'development'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
else
  LOG_PATH = File.join(BASE_PATH, 'log')
  FileUtils.mkdir(LOG_PATH) unless Dir.exists?(LOG_PATH)
  ActiveRecord::Base.logger = Logger.new(File.open(File.join(LOG_PATH, 'database.log'), 'a'))
end