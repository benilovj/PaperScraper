#!/usr/bin/env ruby

require 'sinatra'

set :haml, {:format => :html5 }
enable :sessions

[:what, :why, :how].each do |path|
  get '/' + path.to_s do
    haml :path
  end
end

get '/index' do
  if not params["reset"].nil?
    session[:playing] = true
    session[:score] = 0
    session[:question] = 0
  end
  
  if not session[:playing]
    haml :intro
  else
    haml :question
  end
end