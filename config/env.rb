require 'logger'
require 'active_record'
require 'fileutils'

ENVIRONMENT = ENV['ENVIRONMENT'] || 'development'
dbconf = YAML::load(File.open('config/databases.yml'))[ENVIRONMENT]
ActiveRecord::Base.establish_connection(dbconf)

FileUtils.mkdir('log') unless Dir.exists?('log')
ActiveRecord::Base.logger = Logger.new(File.open('log/database.log', 'a'))