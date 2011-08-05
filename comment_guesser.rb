#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'yaml'
$: << File.expand_path(File.dirname(__FILE__))

require 'lib/game'
require 'PaperScraper'

set :haml, {:format => :html5 }
use Rack::Session::Pool, :expire_after => 2592000

[:what, :why, :how].each do |path|
  get "/#{path}" do
    haml path
  end
end

get '/index' do
  unless session[:game]
    session[:game] = Game.new.to_yaml
    return haml :intro
  end
  @game = YAML.load(session[:game])
  unless @game.finished?
    haml :questions
  else
    haml :present_score
  end
end

post '/index' do
  unless session[:game]
    session[:game] = Game.new.to_yaml
    return haml :intro
  end
  if params["mail"] or params["guardian"]
    @game = YAML.load(session[:game])
    @game.answer = params["mail"] || params["guardian"]
    session[:game] = @game.to_yaml
  end
  
  redirect '/index'
end