require 'mechanize'

class MailScraper
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
    response.body.scan(/yourComments="(.*)"/).flatten.map{|text| postprocess(text)}
  end
  
  protected
  def postprocess(text)
    text.gsub("\\\\", "\\").gsub("\\'", "'")
  end
end

class MailComment < Comment
  validates_absence_of [" Mail", "DM"]
end

PAPERS << Paper.new(:name => 'Daily Mail',
                    :articles_rss_url => 'http://www.dailymail.co.uk/news/headlines/index.rss',
                    :scraper => MailScraper.new,
                    :comment_class_name => "MailComment",
                    :logo => "/images/mail.gif")