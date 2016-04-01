require 'rubygems'
require 'data_mapper'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'C:/Users/Tonje/beerup/lib/authorization'
#require 'leaderboard'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/beerup.db")

class Drink

	include DataMapper::Resource
	
	property :id,        		Serial  
	property :drink_type,		String,		:unique => true, :required => true
	
	has n, :orders#, 'Order', :child_key => [:order_id]
	
end

class Order

	include DataMapper::Resource
	
	property :id,        		Serial  
	property :delivered,		Boolean, 	 :default => false
	property :tablenr,			Integer
	property :drinks_id,		Integer
	
	belongs_to :drink#,			:required => false
	
end

DataMapper.auto_upgrade!

helpers do
	include Sinatra::Authorization
end

# set utf-8 for outgoing
before do
  headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do
  @title = "Welcome to Beerup"
  erb :welcome
end

get '/form' do
	@title = "Beer ordering"
	@drinks = Drink.all()
	@order = Order.all()
	erb :form 
end

post '/order_do' do
	@order = Order.all()
	tablenr = params[:tablenr]
	drinks_id = params[:drinkorder]
	drinks = Drink.get(drinks_id)
	drinktype = drinks.drink_type
	Kernel.puts "invoked create with #{params[:tablenr]} and #{drinktype}"
	@order = Order.new(:tablenr => params[:tablenr], :delivered => false, :drinks_id => drinks_id, :drink_id => drinks_id)
	@order.save
	#drinks = Drink.get(params[:id]).drink_type
	#table = Order.get(params[:id])
	#"1 #{drinks} ordered to table #{tablenr}"
	redirect('/done')
end

get '/new' do
	require_admin
	@title = "Add new drink type"
	erb :new
end

post '/create' do
	require_admin
	drink_type = params[:drink_type]
	Kernel.puts "invoked create with #{params[:drink_type]}"
	@drinks = Drink.new(:drink_type => params[:drink_type])
	@drinks.save
	redirect('/list')
end

get '/list' do
	@title = "All drink types"
	@drinks = Drink.all()
	erb :list
end

get '/orders' do
	require_admin
	@title = "All orders"
	@orders = Order.all(:delivered => false)
	erb :orders
end

post '/delivering' do
	drikkeid = params[:knapp]
	@order = Order.get(drikkeid)
	@order.update(:delivered => true)
	@order.save
	Kernel.puts "Dette er bestilling nr #{drikkeid}"
	redirect('/orders')
end

get '/leaderboard' do
	@title = "Leaderboard"
	@orders = Order.all()
	#finne ut hvilket table som har bestilt mest drikke
	erb :leaderboard
end

get '/done' do
	@title = "Order complete"
	#erb :done
end
	