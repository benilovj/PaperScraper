#!/usr/bin/env ruby

#PaperScraper.rb
#A script to harvest comments from the Daily Mail and Guardian websites and write them to a database, keeping the two sources equally represented

require File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'env')

require 'ostruct'

require 'guardian_scraper'
require 'mail_scraper'
require 'feed_parser'

ActiveRecord::Base.class_eval do
  def self.validates_absence_of(elements)
    validates_each :comment do |model, attr, value|
      elements.each do |element|
        model.errors.add(attr, "cannot contain '#{element}' as it gives away the source") if value =~ Regexp.new(element, Regexp::IGNORECASE)
      end
    end
  end
end

class Comment < ActiveRecord::Base
  MAXIMUM_NUMBER_OF_COMMENTS = 1500
  
  validates_presence_of :comment
  belongs_to :article
  
  class << self 
    def random
      return nil if self.count == 0
      self.first(:offset => rand(self.count))
    end
    
    def keep_only_latest_comments
      delete_all(["created_at < ?", cutoff_timestamp]) if self.count > MAXIMUM_NUMBER_OF_COMMENTS
    end

    def cutoff_timestamp
      self.find(:all, :order => "created_at desc", :limit => MAXIMUM_NUMBER_OF_COMMENTS).last.created_at
    end
  end
  
  def paper
    self.article.paper
  end
end

class GuardianComment < Comment
  validates_absence_of ["Guardian", "====", "Cif", 'This comment was removed by a moderator']
end

class MailComment < Comment
  validates_absence_of [" Mail", "DM"]
end

class Article < ActiveRecord::Base
  validates_uniqueness_of :url
  has_many :comments, :dependent => :destroy, :autosave => true
  
  def scrape
    self.consumed = true
    comments = paper.scraper.download_comments_from(url)
    if comments.empty?
      puts "#{paper.name} article has no comments."
    else
      persist(comments)
    end
    save
  end
  
  def paper
    PAPERS.find_by_name(self[:paper])
  end
  
  protected
  def persist(plain_text_comments)
    candidates = plain_text_comments.take(20).map do |comment|
      paper.comment_class.new(:comment => comment)
    end
    self.comments = candidates.select(&:valid?)
    puts "Number of #{paper.name} comments inserted: #{comments.size}"
  end
end

class Paper < OpenStruct
  include FeedParser
  def replenish_article_urls
    candidate_articles = latest_article_urls_from(articles_rss_url).map{|url| Article.create(:paper => name, :url => url)}
    candidate_articles.select(&:valid?).each(&:save)
  end
  
  def time_to_replenish?
    unconsumed_articles.count < 30
  end
  
  def scrape_next_unconsumed_article_if_exists
    article = unconsumed_articles.first
    article.scrape unless article.nil?
  end
  
  protected
  def unconsumed_articles
    Article.where(:consumed => false, :paper => name)
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
    mail_comment_count = MailComment.count
    guardian_comment_count = GuardianComment.count
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
                    :scraper => MailScraper.new,
                    :comment_class => GuardianComment)
PAPERS << Paper.new(:name => 'Guardian',
                    :articles_rss_url => 'http://feeds.guardian.co.uk/theguardian/commentisfree/rss',
                    :scraper => GuardianScraper.new,
                    :comment_class => MailComment)
