require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/adserver.db")

class Order

	include DataMapper::Resource
	
	property :id,        Serial  
	property :size,		Integer
	
end

DataMapper.auto_upgrade!

# set utf-8 for outgoing
before do
  headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do
  @title = "Order drinks"
  erb :form
end

post '/' do
  @beers_am = "#{params[:post][:beers_am]}"
  @title = "Drinks ordered"
  erb :ordered
end
