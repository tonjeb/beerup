require 'rubygems'
require 'data_mapper'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require_relative 'lib/authorization'
#require 'leaderboard'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/beerup.db")

class Drink

	include DataMapper::Resource
	
	property :id,        		Serial  
	property :drink_type,		String,		:unique => true, :required => true
	property :price,			Integer
					  
	has n, :orders
	
end

class Order

	include DataMapper::Resource
	
	property :id,        		Serial  
	property :delivered,		Boolean, 	 :default => false
	property :tablenr,			Integer
	property :antalld,			Integer
	property :pay,				Boolean,	 :default => false
	
	belongs_to :drink
	
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

get '/admin' do
	require_admin
	@title = "Welcome to the Beerup admin page"
	erb :admin
end

get '/detailed' do
	@title = "Steps to make a 3D model"
	erb :detailed
end

get '/form' do
	@title = "Beer ordering"
	@drinks = Drink.all()
	@order = Order.all()

	erb :form 
end

post '/order_do' do
	a = 1
	if (defined?(b)).nil?  #check if there is any input
		redirect '/form'   #in case of no input, refresh order page
		Kernel.puts "No input"
	else
		tablenr = params[:tablenr]
		Kernel.puts "Drinkorder: #{params[:drinkorder]}, antalld: #{params[:antalld]}"
		Kernel.puts "ok" 
		params["drinkorder"].each do |drink|
			antalld = params["antall_#{drink}"]		
			drinks = Drink.get(drink)
			Kernel.puts "Bestilte: #{antalld} #{drinks.drink_type}"
			@order = Order.new(:tablenr => params[:tablenr], :delivered => false, :drink_id => drink, :antalld => antalld) #:pay=> ...
			@order.save
	end
		
end
	
	
	
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

get '/display' do
	require_admin
	@title = "Photos of each available drink"
	erb :display
end

post '/create' do
	require_admin
	drink_type = params[:drink_type]
	price = params[:price]
	Kernel.puts "invoked create with #{params[:drink_type]}"
	@drinks = Drink.new(:drink_type => params[:drink_type], :price => params[:price])
	@drinks.save
		path = File.join(Dir.pwd, "/public/drinks", params['imagefile'][:filename])
		File.open(path, "wb") do |f|
			f.write(params['imagefile'][:tempfile].read)
			redirect('/list')
		end
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

get '/delivering' do
	drikkeid = params[:orderid]
	@order = Order.get(drikkeid)
	@order.update(:delivered => true)
	@order.save
	Kernel.puts "Dette er bestilling nr #{drikkeid}"
	redirect('/orders')
end

get '/leaderboard' do
	@title = "Leaderboard"
	@orders = Order.all()
	tablenr = params[:tablenr]
	#TODO: finne ut hvilket table som har bestilt mest drikke
	int temp = orders.tablenr
	erb :leaderboard
end

get '/done' do
	@title = "Order complete"
	#TODO: regne ut prisen og tiden det vil ta
	#erb :done
end


post '/upload' do
	resource = Resource.new(:imagefile => make_paperclip_mash(params[:file]))
	halt "There were some errors processing your request..." unless resource.save
end


	