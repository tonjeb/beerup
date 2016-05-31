require 'rubygems'
require 'data_mapper'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require_relative 'lib/authorization'
require 'dm-timestamps'

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
	property :created_at,		DateTime
	
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
	@title = "Admin page"
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
				$price = (drinks.price * antalld.to_i)	
				Kernel.puts "Bestilte: #{antalld} #{drinks.drink_type}"
				@order = Order.new(:tablenr => params[:tablenr], :delivered => false, :drink_id => drink, :antalld => antalld, :pay=> (params[:pay] == "1"), :total_price => $price)
				@order.save
			end
			redirect("/done?price=#{$tot_price}")
		else
			form_error("Error: Missing amount")
		end
		
	end
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
	path = File.join(Dir.pwd, "/public/drinks", @drinks.id.to_s) #params['imagefile'][:filename]
	File.open(path, "wb") do |f|
		f.write(params['imagefile'][:tempfile].read)
		redirect('/deletedrinks')
	end
end

get '/deletedrink/:id' do
	require_admin
	id = params[:id]
	drink = Drink.get(id)
	unless drink.nil?
		path = File.join(Dir.pwd, "/public/drinks", drink.id.to_s)
		File.delete(path)
		drink.destroy
	end
	redirect('/deletedrinks')
end

get '/delete_order/:id' do
	require_admin
	
end

get '/list' do
	@title = "All drink types"
	@drinks = Drink.all()
	erb :list
end

get '/deletedrinks' do
	require_admin
	@title = "Delete drink"
	@drinks = Drink.all()
	erb :deletedrinks
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
	#tst = Order.all(:fields => [:tablenr] :all.count)
	#tst = DataMapper.repository(:default).adapter.select('SELECT tablenr, SUM(total_price) AS total_price FROM orders WHERE delivered = "t" GROUP BY tablenr ORDER BY total_price DESC')
	orders = Order.aggregate(:tablenr, :total_price.sum, :delivered => true, :created_at => [ :lte => 4.hours.ago ], :order => [ :total_price.desc ])
	@list = orders
	Kernel.puts orders.inspect
	#tst.each do |table|
	#	Kernel.puts "test"
		#table.total_price
	#end
	erb :leaderboard
end

get '/done' do
	@title = "Order complete"
	#orders = Order.last()
	#Kernel.puts orders.inspect
	@lastorder = Order.last()
	#@price = orders.total_price
	@price = params[:price]
	
	# Estimated time before delivering drink order: sat to 3 minutes per drink
	@time = (Order.count(:delivered => false) * 3)
	erb :done
end


post '/upload' do
	resource = Resource.new(:imagefile => make_paperclip_mash(params[:file]))
	halt "There were some errors processing your request..." unless resource.save
end