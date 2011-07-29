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
  
  def scrape_next_unconsumed_article_if_exists
    article = Article.where(:consumed => false, :paper => name).first
    unless article.nil?
      article.consumed = true
      article.save
      scraper.scrape(article.url)
    end
  end
  
  protected
  def latest_article_urls
    content = open(articles_rss_url).read
    feed = RSS::Parser.parse(content, false)
    urls = feed.items.reverse.collect(&:link)
    urls.take(10)
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

class MailScraper < Scraper
  def initialize
    super("Daily Mail")
  end

  protected
  def download_comments_from(article_url)
    _, article_path, article_id = article_url.match(/www.dailymail.co.uk(\/.*article-(\d+).*)$/).to_a
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
    response.body.scan(/yourComments="(.*)"/)
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

PAPERS = [
  { :name => 'Mail',     
    :articles_rss_url => 'http://www.dailymail.co.uk/news/headlines/index.rss',
    :scraper => MailScraper.new
  },
  { :name => 'Guardian',
    :articles_rss_url => 'http://feeds.guardian.co.uk/theguardian/commentisfree/rss',
    :scraper => GuardianScraper.new
  }
].collect {|map| Paper.new(map)}