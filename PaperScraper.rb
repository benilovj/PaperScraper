#!/usr/bin/env ruby

#PaperScraper.rb
#My first ruby application
#A script to harvest comments from the Daily Mail and Guardian websites and write them to a database, keeping the two sources equally represented
#Version 0.1

#never scrapes the same URL twice while logs exist

$: << File.expand_path(File.dirname(__FILE__))
$script_path = File.expand_path(File.dirname(__FILE__))

require 'open-uri'
require 'hpricot'
require 'mechanize'
require 'rss/2.0'
require 'iconv'
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
      delete_all(["created_at < ?", cutoff_timestamp])
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

PAPERS = ['Mail', 'Guardian']

class Commissioner 
   
  def commission_feeds
    rssdruid = RSSDruid.new
    rssdruid.maintain_feeds
    return nil
  end
   
  def balance_data
    datadruid = DataDruid.new
    datadruid.table_maintenance
    @prescription = datadruid.prescribe_comments
  end
    
  def run_scrape
    scraperdruid = ScraperDruid.new(@prescription)
    scraperdruid.invoke_scraper
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

#add a string function to escape single quotes
class String
  def escape_single_quotes
    self.gsub(/'/, "\\\\'")
  end
end

class Scraper

  attr_reader :output
  attr_reader :url
  attr_reader :paper
  
  def scrape
    comments = download_comments
    to_array(comments)
    begin
    write_data
    rescue Exception
    puts "#{@paper} article has no comments."
    end
  end

end 

class DailyMailScraper < Scraper
  
  def initialize ( url )
    @a = Mechanize.new
    @url = url
    @paper = "Daily Mail"
  end

  protected
 
  def download_comments 
    article_id = @url.slice(/article-\d{5,7}/)
    article_id = article_id.slice(/\d{5,7}/)
    article_path = @url.split('http://www.dailymail.co.uk')[1].to_s
    comments_output = @a.post('http://www.dailymail.co.uk/dwr/call/plaincall/AjaxReaderComments.paginateReaderComments.dwr',
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
  end 
  
  def to_array (comments)
    chopped = comments.body.split(/yourComments="(.*)"/)
    @output = chopped[1...-1].values_at(* chopped.each_index.select {|i| i.even?})
  end

  def write_data
    i = 0
    @output[1..20].slice(1..-1).each do |comment| 
      comment.gsub!(/^u[0-9][0-9]/) { |match| "\\" + match }
      i += 1
      Comment.create(:comment => comment, :url => url, :paper => paper).save!
    end
    puts "Number of Daily Mail comments inserted: #{i}"
  end 
  
end

class GuardianScraper < Scraper
  def initialize ( url )
    @url = url
    @scrape = open(url)
    @paper = "Guardian"
  end

  protected

  def download_comments
    @scrape.rewind
    comments = Hpricot(Iconv.conv('utf-8', @scrape.charset, @scrape.readlines.join("\n"))).search("div[@class='comment-body']")
  end
  
  def to_array (comments)
    @output = comments.collect do |comment|
      comment.inner_text[4...-4]
      end
  end

  def write_data
    i = 0
    self.output[1..20].slice(1..-1).each do |comment| 
      i += 1
      Comment.create(:comment => comment.escape_single_quotes.strip, :url => url, :paper => paper).save!
    end
    puts "Number of Guardian comments inserted: #{i}"
  end
end

#database functions and maintenance

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
 
  private
end

class ArticleUrls
  def get_urls
    @urls ||= []
    content = ""
    open(@source) do |s| content = s.read end
    @feed = RSS::Parser.parse(content, false)
    @feed.items.reverse.each { |each| @urls << each.link }
    @urls.slice(0..11)
    end
end

class MailUrls < ArticleUrls
  def initialize
    @source = 'http://www.dailymail.co.uk/news/headlines/index.rss'
    @urls = [:source => 'Daily Mail']
  end
end

class GuardianUrls < ArticleUrls
  def initialize
    @source = 'http://feeds.guardian.co.uk/theguardian/commentisfree/rss'
    @urls = [:source => 'Guardian']
  end
end

class RSSDruid

  def maintain_feeds
    PAPERS.each do |paper|
      if time_to_replenish?(paper)
        urlset = eval( paper + "Urls.new.get_urls")
        urlset[1..10].each do |url|
        File.open( $script_path + "/" + paper,'a') do |f|
          f.puts url end
        end # urlset iterator
      end #time to replenish if
      remove_duplicates(paper)        
    end #papers iterator
  end

  private

  def time_to_replenish? ( file )
    begin
      if File.readlines($script_path + "/" + file).size < 30
          true
        else false
        end
      rescue Exception
      FileUtils.touch($script_path + "/" + file)
      retry
    end
  end            

  def remove_duplicates(paper)
    cleaned_file_contents = File.readlines($script_path + "/" + paper).uniq   
    File.new($script_path + "/" + paper, "w").close
    cleaned_file_contents.each do |url|
      File.open($script_path + "/" + paper, "a") do |f| f.puts url end
    end
  end    

end

class ScraperDruid

  def initialize(prescription)
    @prescription = prescription
  end

  def invoke_scraper
    if @prescription.include? "Mail"
      DailyMailScraper.new(FileClipper.new('Mail', 'log/story.log').get_line).scrape end
    if @prescription.include? "Guardian"
      GuardianScraper.new(FileClipper.new('Guardian', 'log/story.log').get_line).scrape end
  end

end 

class FileClipper

  def initialize(queuefile, logfile)
    @queuefile = $script_path + "/" + queuefile
    @logfile = $script_path + "/" + logfile
  end

  def get_line
    line = next_line
    while in_logfile?(line)
      line = next_line
    end
    log_line(line)
    line
  end

  private

  def next_line
    queue = []
    File.open(@queuefile, "r").each_line { |line| queue << line }
    return "No lines in queuefile" if queue.empty?
    File.open(@queuefile, "w").truncate(0)  
    selected_line = queue.shift
    File.open(@queuefile, "a") { |f| f.puts (queue.join) }  
    selected_line
  end

  def in_logfile?(string_to_check)
    match = File.new(@logfile, "r").detect { |log_entry| log_entry == string_to_check }
    if match == nil 
      return false
    else
      return true
    end
  end

  def log_line(line)
    log = File.new(@logfile, "a")
    log.write(line + "\n")
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
