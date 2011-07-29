#!/usr/bin/env ruby

#PaperScraper.rb
#My first ruby application
#A script to harvest comments from the Daily Mail and Guardian websites and write them to a database, keeping the two sources equally represented
#Version 0.1

$: << File.expand_path(File.dirname(__FILE__))
$script_path = File.expand_path(File.dirname(__FILE__))

require 'open-uri'
require 'rss/2.0'
require 'iconv'
require 'ostruct'

require 'hpricot'
require 'mechanize'
require 'logger'
require 'active_record'

environment = ENV['ENVIRONMENT'] || 'development'
dbconf = YAML::load(File.open('config/databases.yml'))[environment]
ActiveRecord::Base.establish_connection(dbconf) 
ActiveRecord::Base.logger = Logger.new(File.open('log/database.log', 'a'))

class Comment < ActiveRecord::Base
  MAXIMUM_NUMBER_OF_COMMENTS = 1500
  REFERENCES_TO_SOURCE = [" Mail", "Guardian", "====", "Cif", "DM"]
  JUNK = ['This comment was removed by a moderator', 'u00']
  
  validates_presence_of :comment
  validate :absence_of_references_to_source
  validate :absence_of_junk
  
  class << self 
    def mail
      self.where(:paper => 'Daily Mail')
    end
    
    def guardian
      self.where(:paper => 'Guardian')
    end
    
    def keep_only_latest_comments
      delete_all(["created_at < ?", cutoff_timestamp]) if self.count > MAXIMUM_NUMBER_OF_COMMENTS
    end

    def cutoff_timestamp
      self.find(:all, :order => "created_at desc", :limit => MAXIMUM_NUMBER_OF_COMMENTS).last.created_at
    end
  end
  
  protected
  def absence_of_references_to_source
    REFERENCES_TO_SOURCE.each do |reference_to_source|
      errors.add(:comment, "cannot contain reference to source: #{reference_to_source}") if
            comment =~ Regexp.new(reference_to_source, Regexp::IGNORECASE)
    end
  end

  def absence_of_junk
    JUNK.each do |junk|
      errors.add(:comment, "cannot contain junk: #{junk}") if
            comment =~ Regexp.new(junk, Regexp::IGNORECASE)
    end
  end
end

class Article < ActiveRecord::Base
  validates_uniqueness_of :url
end

class Paper < OpenStruct
  def replenish_article_urls
    latest_article_urls().each do |url|
      article = Article.create(:paper => name, :url => url)
      article.save if article.valid?
    end
  end
  
  def time_to_replenish?
    Article.where(:paper => name).count < 30
  end
  
  protected
  def latest_article_urls
    content = open(articles_rss_url).read
    feed = RSS::Parser.parse(content, false)
    urls = feed.items.reverse.collect(&:link)
    urls.take(10)
  end
end

PAPERS = [
  { :name => 'Mail',     :articles_rss_url => 'http://www.dailymail.co.uk/news/headlines/index.rss' },
  { :name => 'Guardian', :articles_rss_url => 'http://feeds.guardian.co.uk/theguardian/commentisfree/rss' }
].collect {|map| Paper.new(map)}

class Commissioner 
  def commission_feeds
    RSSDruid.new.maintain_feeds
  end
   
  def balance_data
    datadruid = DataDruid.new
    datadruid.table_maintenance
    @prescription = datadruid.prescribe_comments
  end
    
  def run_scrape
    ScraperDruid.new(@prescription).invoke_scraper
  end

  def complete_cycle
    puts "Housekeeping..."
    commission_feeds
    balance_data
    puts "Scraping..."
    run_scrape
  end

  def just_a_scrape
    puts "Checking databases..."
    balance_data
    puts "Scraping began at #{Time.now}..."
    run_scrape
    puts "Scraping complete at #{Time.now}"
  end   
end   

class Scraper
  def initialize(paper)
    @paper = paper
  end
  
  def scrape(article_url)
    comments = download_comments_from(article_url)
    if comments.empty?
      puts "#{@paper} article has no comments."
    else
      persist(comments, article_url)
    end
  end
  
  protected
  def persist(comments, article_url)
    comments_to_save = comments.take(20)
    comments_to_save.each do |comment| 
      comment = Comment.create(:comment => comment, :url => article_url, :paper => @paper)
      comment.save if comment.valid?
    end
    puts "Number of #{@paper} comments inserted: #{comments_to_save.size}"
  end
end 

class DailyMailScraper < Scraper
  def initialize
    super("Daily Mail")
  end

  protected
  def download_comments_from(article_url)
    _, article_path, article_id = article_url.match(/www.dailymail.co.uk(\/.*article-(\d+).*)$/).to_a
    5.times do
      response = Mechanize.new.post(
        'http://www.dailymail.co.uk/dwr/call/plaincall/AjaxReaderComments.paginateReaderComments.dwr',
        {'callCount'=>'1',
        'page'=>"#{article_path}",
        'httpSessionId'=>'',
        'scriptSessionId'=>'',
        'c0-scriptName'=>'AjaxReaderComments',
        'c0-methodName'=>'paginateReaderComments',
        'c0-id'=>'0',
        'c0-param0'=>'string:' + article_id,
        'c0-param1'=>'number:1',
        'c0-param2'=>'number:100',
        'c0-param3'=>'string:newest',
        'batchId'=>'0' } 
      )
      comments = response.body.scan(/yourComments="(.*)"/)
      return comments unless comments.empty?
    end
    return []
  end
end

class GuardianScraper < Scraper
  def initialize
    super("Guardian")
  end

  protected
  def download_comments_from(article_url)
    comment_nodes = []
    scrape = open(article_url) do |f|
      page_markup = Iconv.conv('utf-8', f.charset, f.read)
      comment_nodes = Hpricot(page_markup).search("div[@class='comment-body']")
    end
    comment_nodes.map(&:inner_text).map(&:strip)
  end  
end

class DataDruid
  def initialize
    @mail_comment_count = Comment.mail.count
    @guardian_comment_count = Comment.guardian.count
    puts "Table status: #{@guardian_comment_count} Guardian comments. #{@mail_comment_count} Daily Mail comments."
  end

  def table_maintenance
    Comment.keep_only_latest_comments
  end
  
  def prescribe_comments
    if @guardian_comment_count > (@mail_comment_count + 20)
      prescription = ["Mail"]
    elsif @mail_comment_count > (@guardian_comment_count + 20)
      prescription = ["Guardian"]
    else 
      prescription = ["Mail", "Guardian"]
    end
  end
end

class RSSDruid
  def maintain_feeds
    PAPERS.each do |paper|
      paper.replenish_article_urls if paper.time_to_replenish?
    end
  end
end

class ScraperDruid
  def initialize(prescription)
    @prescription = prescription
  end

  def invoke_scraper
    if @prescription.include? "Mail"
      article = Article.where(:consumed => false, :paper => "Mail").first
      unless article.nil?
        article.consumed = true
        article.save
        DailyMailScraper.new.scrape(article.url)
      end
    end
    if @prescription.include? "Guardian"
      article = Article.where(:consumed => false, :paper => "Guardian").first
      unless article.nil?
        article.consumed = true
        article.save
        GuardianScraper.new.scrape(article.url)
      end
    end
  end
end
    
if ARGV[0] == "--maintain"
  c = Commissioner.new
  puts "Feed maintenance started at #{Time.now}"
  c.commission_feeds
  puts "Table maintenance started at #{Time.now}"
  c.balance_data
  puts "Maintenance complete at #{Time.now}"
end

Commissioner.new.just_a_scrape if ARGV[0] == '--execute'
