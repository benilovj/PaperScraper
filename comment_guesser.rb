#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'yaml'
$: << File.expand_path(File.dirname(__FILE__))

require 'lib/game'
require 'PaperScraper'

set :haml, {:format => :html5 }
use Rack::Session::Pool, :expire_after => 60 * 60 * 24 * 30

[:what, :why, :how, :intro].each do |path|
  get "/#{path}" do
    haml path
  end
end

get "/" do
  redirect to("/intro")
end

before '/game' do
  session[:game] = Game.new.to_yaml unless session[:game]
  @game = YAML.load(session[:game])
end

get '/game' do
  return haml :questions unless @game.finished?
  haml :present_score
end

post '/game' do
  if params["mail"] or params["guardian"]
    @game.answer = params["mail"] || params["guardian"]
  end
  redirect to('/game')
end

after '/game' do
  session[:game] = @game.to_yaml
end