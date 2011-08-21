#!/usr/bin/env ruby

#PaperScraper.rb
#A script to harvest comments from the Daily Mail and Guardian websites and write them to a database, keeping the two sources equally represented

require 'ostruct'

require File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'env')
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
    PAPERS[self[:paper]]
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
    latest_article_urls_from(articles_rss_url).each {|url| Article.create(:paper => name, :url => url)}
  end
  
  def time_to_replenish?
    unconsumed_articles.count < 30
  end
  
  def scrape_next_unconsumed_article_if_exists
    article = unconsumed_articles.first
    article.scrape unless article.nil?
  end
  
  def status
    "#{comment_count} #{name} comments."
  end
  
  def comment_count
    comment_class.count
  end
  
  def comment_class
    Kernel.const_get(comment_class_name.to_sym)
  end
  
  def ==(other)
    self.name == other.name
  end
  
  def random_comment
    comment_class.random
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
    max = max_comment_count_for_a_paper
    papers_to_scrape = @papers.select {|paper| paper.comment_count < max - 20}
    papers_to_scrape = @papers if papers_to_scrape.empty?
    
    papers_to_scrape.each(&:scrape_next_unconsumed_article_if_exists)
  end
  
  def replenish
    @papers.select(&:time_to_replenish?).each(&:replenish_article_urls)
  end
  
  def [](name)
    @papers.detect {|paper| paper.name == name}
  end
  
  def status
    "Table status: " + @papers.map(&:status).join(" ")
  end
  
  protected
  def max_comment_count_for_a_paper
    @papers.collect(&:comment_count).max
  end
end

PAPERS = Papers.new

require 'guardian'
require 'mail'