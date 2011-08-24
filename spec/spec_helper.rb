$: << File.join(File.expand_path(File.dirname(__FILE__)), '..')

require 'PaperScraper'

RSpec::Matchers.define :be_included_in do |expected|
  match do |actual|
    expected.include?(actual)
  end
end