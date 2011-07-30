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
  if params["action"] == "reset"
    session[:playing] = true
    session[:score] = 0
    session[:question] = 1
  end
  
  if session[:playing]
    if session[:score] <= 10
      haml :questions
    else
      haml :present_score
    end
  else
    haml :intro
  end
end