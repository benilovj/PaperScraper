#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'yaml'
require 'haml'

$: << File.expand_path(File.dirname(__FILE__))
require 'lib/game'
require 'PaperScraper'

set :haml, {:format => :html5 }
use Rack::Session::Pool, :expire_after => 60 * 60 * 24 * 30

get "/" do
  haml :intro
end

[:what, :why, :how].each do |path|
  get "/#{path}" do
    haml path
  end
end

before /game/ do
  @game = session[:game] ? YAML.load(session[:game]) : Game.new
end

post '/game/new' do
  @game = Game.new
  redirect to('/game')
end

get '/game' do
  if @game.finished?
    haml :present_score
  else
    haml :question
  end
end

post '/game/answer/:paper' do |paper|
  pass unless @game.valid_choice?(paper)
  @game.answer = paper
  redirect to('/game')
end

after /game/ do
  session[:game] = @game.to_yaml
end