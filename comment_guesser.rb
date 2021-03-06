#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'yaml'
require 'haml'
require 'sass'
require 'uri'

$: << File.expand_path(File.dirname(__FILE__))
require 'lib/game'
require 'PaperScraper'

set :haml, {:format => :html5 }
use Rack::Session::Pool, :expire_after => 60 * 60 * 24 * 30

get "/" do
  haml :intro
end

get '/stylesheet.css' do
  sass :stylesheet
end

[:what, :why, :how].each do |path|
  get "/#{path}" do
    haml path
  end
end

def new_game
  Game.new([PAPERS["Daily Mail"], PAPERS["Guardian"]])
end

before /game/ do
  @game = session[:game] ? Game.load(YAML.load(session[:game])) : new_game
end

get '/game/new' do
  redirect to('/')
end

post '/game/new' do
  @game = new_game
  redirect to('/game')
end

get '/game' do
  if @game.finished?
    haml :present_score
  else
    haml :question
  end
end

post '/game/answer/:paper_name' do |paper_name|
  paper = PAPERS[URI.unescape(paper_name)]
  pass if paper.nil? or not @game.valid_choice?(paper)
  @game.answer = paper
  haml :reaction, :layout => !request.xhr?
end

after /game/ do
  session[:game] = @game.dump.to_yaml
end

get '/rankings/:paper_name' do |paper_name|
  @paper = PAPERS[URI.unescape(paper_name)]
  pass if @paper.nil?
  @comment_texts = GameResult.top_ten_comments_guessed_from(@paper).map(&:comment)
  haml :top_ten
end