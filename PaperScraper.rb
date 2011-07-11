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
require 'mysql'
require 'rss/2.0'
require 'open-uri'

#set up db connection
require $script_path + '/db-config'
$db_user = Database.new.db_user
$db_pass = Database.new.db_pass
$dbh = Mysql.real_connect("localhost", $db_user, $db_pass, "papers")

$papers = ['Mail', 'Guardian']

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

  
  def download_comments #fetch raw comments from the website.
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

  #writes comments to the database
  def write_data
    i = 0
    @output[1..20].slice(1..-1).each do |comment| 
      i += 1
      $dbh.query("INSERT INTO comments (comment, url, paper)
        VALUES (\'#{comment}\', \'#{self.url}\', \'#{self.paper}\')"
      )
      end
    puts "Number of Daily Mail comments inserted: #{i}"
  end 
  
end

#scraper for Guardian pages
class GuardianScraper < Scraper
  
  def initialize ( url )
    @url = url
    @scrape = Hpricot(open(url))
    @paper = "Guardian"
  end

  #fetch the first page of comments from the article
  def download_comments
    comments = @scrape.search("div[@class='comment-body']")
  end
  
  def to_array (comments)
    @output = comments.collect do |comment|
      comment.inner_text[4...-4]
      end
  end

  #write the comments to the database
  def write_data
    i = 0
    self.output[1..20].slice(1..-1).each do |comment| 
      i += 1
      $dbh.query("INSERT INTO comments (comment, url, paper)
         VALUES (\'#{comment.escape_single_quotes.strip}\', \'#{self.url}\', \'#{self.paper}\')"
        )
      end
    puts "Number of Guardian comments inserted: #{i}"
  end 

end   

#database functions and maintenance

class DataDruid

  def initialize
    @mail_comments = $dbh.query("SELECT COUNT(*) FROM comments WHERE paper = 'Daily Mail'").fetch_row
    @guardian_comments = $dbh.query("SELECT COUNT(*) FROM comments WHERE paper = 'Guardian'").fetch_row
    @total_rows = $dbh.query("SELECT COUNT(*) FROM comments WHERE 1 = 1").fetch_row
    puts "Table status: #{@guardian_comments[0]} Guardian comments. #{@mail_comments[0]} Daily Mail comments."
  end

  def trim_rows( numberofrows )
    $dbh.query("DELETE FROM comments WHERE id < #{numberofrows.to_i}")
  end
  
  def table_maintenance
    remove_references_to_source
    remove_moderator_notices
    clean_empty_comments
    if @total_rows[0].to_i > 5000
      trim_rows(@total_rows - 5000) 
      # reset the id column or chaos will ensue
      $dbh.query("ALTER TABLE comments DROP COLUMN id;")
      $dbh.query("ALTER TABLE comments ADD id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                              ADD PRIMARY KEY (id);")
      puts "Database was pruned"  
      end
  end
    
  def remove_references_to_source
    $dbh.query("DELETE FROM `comments` WHERE comment regexp '[[:space:]]Mail'")
    $dbh.query("DELETE FROM `comments` WHERE comment regexp 'Guardian'")
  end

  def remove_moderator_notices
    $dbh.query("DELETE FROM `comments` WHERE comment regexp 'This comment was removed by a moderator'")
  end

  def clean_empty_comments
    $dbh.query("DELETE FROM `comments` WHERE comment = ''")
  end

  #this lets you know if the papers are out of balance - the prescription dictates what gets scraped
    def prescribe_comments
      if @guardian_comments[0].to_i > (@mail_comments[0].to_i + 20)
          prescription = ["Mail"]
      elsif @mail_comments[0].to_i > (@guardian_comments[0].to_i + 20)
          prescription = ["Guardian"]
      else 
          prescription = ["Mail", "Guardian"]
      end
    end
        
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

  def maintain_feeds
    $papers.each do |paper|
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

end

class ScraperDruid

  def initialize(prescription)
    @prescription = prescription
  end

  def invoke_scraper
    if @prescription.include? "Mail"
      DailyMailScraper.new(FileClipper.new('Mail', 'log').get_line).scrape end
    if @prescription.include? "Guardian"
      GuardianScraper.new(FileClipper.new('Guardian', 'log').get_line).scrape end
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
    puts "Connecting to DB..."
    $dbh = Mysql.real_connect("localhost", $db_user, $db_pass, "papers")
    puts "Housekeeping..."
    commission_feeds
    balance_data
    puts "Scraping..."
    run_scrape
    $dbh.close
  end

  def just_a_scrape
    puts "Connecting to DB..."
    $dbh = Mysql.real_connect("localhost", $db_user, $db_pass, "papers")
    puts "Checking databases..."
    balance_data
    puts "Scraping began at #{Time.now}..."
    run_scrape
    $dbh.close  
    puts "Scraping complete at #{Time.now}"
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
