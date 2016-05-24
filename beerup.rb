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
	property :total_price,		Integer
	
	belongs_to :drink
	
end

DataMapper.auto_upgrade!

helpers do
	include Sinatra::Authorization
	
	def form_error(message)
		@title = "Beer ordering"
		@drinks = Drink.all()
		@order = Order.all()
		@error = message
		
		Kernel.puts "error was #{message}"
		
		erb :form
	end
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
	tablenr = params[:tablenr]
	Kernel.puts "Drinkorder: #{params[:drinkorder]}, antalld: #{params[:antalld]}"
	$tot_price = 0
	
	if (params[:drinkorder].nil?)
		form_error("Error: Form cannot be empty")
		#redirect('/form')
	else
		# Loop through all orders once to check for errors
		order_error = false
		params["drinkorder"].each do |drink|
			drinks = Drink.get(drink)
			antalld = params["antall_#{drink}"]		
			if(antalld.nil? || antalld.empty?)
				order_error = true
				Kernel.puts "Error: Amount of #{drinks.drink_type} is blank"
			end
		end
		
		# Loop through to save orders
		if(order_error == false)
			params["drinkorder"].each do |drink|
				drinks = Drink.get(drink)
				antalld = params["antall_#{drink}"]	
				$tot_price += (drinks.price * antalld.to_i)	
						
				Kernel.puts "Bestilte: #{antalld} #{drinks.drink_type}"
				@order = Order.new(:tablenr => params[:tablenr], :delivered => false, :drink_id => drink, :antalld => antalld, :pay=> (params[:pay] == "1"), :total_price => $tot_price)
				@order.save
				@ordered = "Your order costs  tot_price and you chose to pay by cash/card"
			end
			redirect('/done')
		else
			form_error("Error: Missing amount")
		end
		
	end
end
	

	#table = Order.get(params[:id])
	#"1 #{drinks} ordered to table #{tablenr}"

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
	orders = Order.last()
	Kernel.puts orders.inspect
	@lastorder = orders
	@price = orders.total_price
	
	# Estimated time before delivering drink order: sat to 3 minutes per drink
	@time = (Order.count(:delivered => false) * 3)
	erb :done
end


post '/upload' do
	resource = Resource.new(:imagefile => make_paperclip_mash(params[:file]))
	halt "There were some errors processing your request..." unless resource.save
end


	