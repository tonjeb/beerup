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
#	include Paperclip::Resource
	
	property :id,        		Serial  
	property :drink_type,		String,		:unique => true, :required => true
	property :price,			Integer
	
#	has_attached_file :file,
#					  :url => "C:\Ruby22\lib\ruby\gems\2.2.0\gems\paperclip-4.3.6"
#					  :path => "#{APP_ROOT}/public/system/:attachment/:id/:style/:basename.:extension"
					  
	has n, :orders
	
end

class Order

	include DataMapper::Resource
	
	property :id,        		Serial  
	property :delivered,		Boolean, 	 :default => false
	property :tablenr,			Integer
	property :antalld,			Integer
	
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

get '/form' do
	@title = "Beer ordering"
	@drinks = Drink.all()
	@order = Order.all()
	erb :form 
end

post '/order_do' do
	@order = Order.all()
	tablenr = params[:tablenr]
	antalld = params[:antalld]
	drinks_id = params[:drinkorder]
	drinks = Drink.get(drinks_id)
	Kernel.puts "invoked create with #{params[:tablenr]} and #{params[:antalld]}"
	@order = Order.new(:tablenr => params[:tablenr], :delivered => false, :drink_id => drinks_id, :antalld => antalld)
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
	price = params[:price]
	Kernel.puts "invoked create with #{params[:drink_type]}"
	@drinks = Drink.new(:drink_type => params[:drink_type], :price => params[:price])
	#if 
	@drinks.save
		#path = File.join(Dir.pwd, "/public/drinks", @drink.filename)
		#File.open('/public/drinks' + params['imagefile'][:filename], "w") do |f|
		#	f.write(params['imagefile'][:tempfile].read)
		#end
		#Kernel.puts "juuuhuuuu"
	#else
		redirect('/list')
	#end
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
	#finne ut hvilket table som har bestilt mest drikke
	erb :leaderboard
end

get '/done' do
	@title = "Order complete"
	#erb :done
end


post '/upload' do
	resource = Resource.new(:file => make_paperclip_mash(params[:file]))
	halt "There were some errors processing your request..." unless resource.save
end

#def make_paperclip_mash(file_hash)
 # mash = Mash.new
 # mash['tempfile'] = file_hash[:tempfile]
 # mash['filename'] = file_hash[:filename]
 # mash['content_type'] = file_hash[:type]
 # mash['size'] = file_hash[:tempfile].size
 # mash
#end
	