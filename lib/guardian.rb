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

class GuardianComment < Comment
  validates_absence_of ["Guardian", "====", "Cif", 'This comment was removed by a moderator']
end

PAPERS << Paper.new(:name => 'Guardian',
                    :articles_rss_url => 'http://feeds.guardian.co.uk/theguardian/commentisfree/rss',
                    :scraper => GuardianScraper.new,
                    :comment_class_name => "GuardianComment",
                    :logo => "/images/guardian.png")