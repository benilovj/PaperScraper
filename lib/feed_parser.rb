require 'open-uri'
require 'rss/2.0'

module FeedParser
  def latest_article_urls_from(feed_url)
    content = open(feed_url).read
    feed = RSS::Parser.parse(content, false)
    feed.items.reverse.collect(&:link)
  end
end