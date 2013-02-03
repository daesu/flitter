require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require './database/database'
require 'will_paginate'
require 'will_paginate/array'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'

helpers do
	include WillPaginate::ViewHelpers
end

set :public_folder, File.dirname(__FILE__) + '/'
enable :sessions
set :sessions, true

def pagination(limit, user)

	page = params[:page] || 1
	page = page.to_i
	page -= 1
	offset = limit * page

	if user.nil? 
		totalflitts = Flitt.all.count
		flitt = Flitt.all :limit => limit, :offset => offset, :order => :created_at.desc	 
		@flitt = WillPaginate::Collection.create(page + 1, limit, totalflitts) {|p| p.replace flitt }
	else
		totalflitts = Flitt.where(:user_id => user ).all.count
		flitt = Flitt.where(:user_id => user ).all :limit => limit, :offset => offset, :order => :created_at.desc
		@flitt = WillPaginate::Collection.create(page + 1, limit, totalflitts) {|p| p.replace flitt }
	end
	return @flitt
end

# If a user's logged in 
def logged_in
	if session[:user].nil?
		if	session[:id].nil?
			session[:id] ||= random_string(20)
		end
	else
		return session[:id]
	end
end

class Main

	# Called for each GET
	before do   
		logged_in # Check login status
	end

	# homepage
	get '/?' do
		redirect "/flitter"
	end

	get '/flitter/?' do	
			@update = pagination(10, nil) # Show all flitts (from all users)
			erb :index		
	end

	get '/flitter/user/login/?' do
		erb :login
	end

	post '/flitter/user/login/?' do
		name = params["login"]
		pass = params["password"]
	
		if name == "" || pass == ""
			@error = "Fields cannot be blank"
			halt erb :login
		elsif session[:user] = User.authenticate(name, pass)
			session[:user] == User.authenticate(name, pass)
			redirect "/flitter/#{session[:user].login}"
		else
			@error = "Username and Password do not match"
			halt erb :login
		end
	end

	# logout
	get '/flitter/user/logout/?' do
		session[:id] = nil
		session[:user] = nil
		redirect '/flitter'
	end

	get '/flitter/user/signup/?' do
		erb :signup
	end

	get '/flitter/user/fbsignup' do
		erb :fbsignup
	end

	post '/flitter/user/signup/?' do
		u = User.new
		u.login = params["login"]
		u.firstlastname = params["firstlastname"]
		u.password = params["password"]
		u.email = params["email"]

		# if user created successfully, go to login page
		if u.save
			redirect "/flitter/user/login"
		else
			@error = u.errors.map{|k,v| "#{k}: #{v}"}.join("<br/> ")
			halt erb :signup
		end
	end

	# List all site members
	get '/flitter/user/list/?' do
		@u = User.all
		erb :list
	end

	# Go to Users homepage (Protected)
	get "/flitter/:name" do 
		if session[:user].nil?
			redirect "/flitter"
		elsif params[:name] != session[:user].login
			redirect "/flitter/#{:name}"
			erb :userhome				
		else
			@currentuser = session[:user]			
			@update = pagination(10, session[:user].login)	
				
			erb :userhome
		end
	end

	# Go to user homepage (Public)
	get "/flitter/user/:name/?" do 
		exist = User.where(:login => params[:name] ).first
		if exist.nil?
			@error = "No such User exists"
			halt erb :userpublichome
		else
			@update = pagination(10, params[:name])
			@who = params[:name]
			erb :userpublichome
		end
	end

	# post a new Flitt
	post "/flitter/:name" do  
		update = Flitt.new  
		update.user_id = session[:user].login
		update.content = params[:content] 

		if update.save
			redirect "/flitter/#{session[:user].login}"
		else
			@error = "Sorry something went wrong"
			halt erb :userhome
		end
	end  

end
