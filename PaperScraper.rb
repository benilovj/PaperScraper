#!/usr/bin/env ruby

#PaperScraper.rb
#My first ruby application
#A script to harvest comments from the Daily Mail and Guardian websites and write them to a database, keeping the two sources equally represented
#Version 0.1

require File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'env')

require 'open-uri'
require 'rss/2.0'
require 'ostruct'

require 'guardian_scraper'
require 'mail_scraper'

class Comment < ActiveRecord::Base
  MAXIMUM_NUMBER_OF_COMMENTS = 1500
  REFERENCES_TO_SOURCE = [" Mail", "Guardian", "====", "Cif", "DM"]
  JUNK = ['This comment was removed by a moderator', 'u00']
  
  validates_presence_of :comment
  validate :absence_of_references_to_source
  validate :absence_of_junk
  
  class << self 
    def mail
      self.where(:paper => 'Mail')
    end
    
    def guardian
      self.where(:paper => 'Guardian')
    end
    
    def random
      # TODO: make this random!
      self.find(:first)
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
  
  def scrape
    self.consumed = true
    save
    comments = paper.scraper.download_comments_from(url)
    if comments.empty?
      puts "#{name} article has no comments."
    else
      persist(comments)
    end
  end
  
  def paper
    PAPERS.find_by_name(self[:paper])
  end
  
  protected
  def persist(plain_text_comments)
    candidates = plain_text_comments.take(20).map do |comment|
      Comment.create(:comment => comment, :url => url, :paper => paper.name)
    end
    comments = candidates.select(&:valid?)
    comments.map(&:save)
    puts "Number of #{paper.name} comments inserted: #{comments.size}"
  end
end

class Paper < OpenStruct
  def replenish_article_urls
    candidate_articles = latest_article_urls.map{|url| Article.create(:paper => name, :url => url)}
    candidate_articles.select(&:valid?).each(&:save)
  end
  
  def time_to_replenish?
    Article.where(:paper => name).count < 30
  end
  
  def scrape_next_unconsumed_article_if_exists
    article = Article.where(:consumed => false, :paper => name).first
    article.scrape unless article.nil?
  end
  
  protected
  def latest_article_urls
    content = open(articles_rss_url).read
    feed = RSS::Parser.parse(content, false)
    feed.items.reverse.collect(&:link)
  end
end

class Papers
  def initialize
    @papers = []
  end
  
  def <<(paper)
    @papers << paper
  end
  
  def run_scrape
    mail_comment_count = Comment.mail.count
    guardian_comment_count = Comment.guardian.count
    case
    when guardian_comment_count > mail_comment_count + 20 then
      prescription = [find_by_name("Mail")]
    when mail_comment_count > guardian_comment_count + 20 then
      prescription = [find_by_name("Guardian")]
    else 
      prescription = @papers
    end
    
    prescription.each(&:scrape_next_unconsumed_article_if_exists)
  end
  
  def replenish
    @papers.select(&:time_to_replenish?).each(&:replenish_article_urls)
  end
  
  def find_by_name(name)
    @papers.detect {|paper| paper.name == name}
  end
end

PAPERS = Papers.new
PAPERS << Paper.new(:name => 'Mail',
                    :articles_rss_url => 'http://www.dailymail.co.uk/news/headlines/index.rss',
                    :scraper => MailScraper.new)
PAPERS << Paper.new(:name => 'Guardian',
                    :articles_rss_url => 'http://feeds.guardian.co.uk/theguardian/commentisfree/rss',
                    :scraper => GuardianScraper.new)
