require 'open-uri'
require 'hpricot'
require 'iconv'

class GuardianScraper
  def download_comments_from(article_url)
    comment_nodes = []
    scrape = open(article_url) do |f|
      page_markup = Iconv.conv('utf-8', f.charset, f.read)
      comment_nodes = Hpricot(page_markup).search("div[@class='comment-body']")
    end
    comment_nodes.map(&:inner_text).map(&:strip)
  end   
end