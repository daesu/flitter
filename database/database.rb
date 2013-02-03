require 'rubygems'
require 'digest/sha1'
require 'date'
require 'mongo_mapper'
require 'uri'

if ENV['MONGOHQ_URL']
	uri = URI.parse(ENV['MONGOHQ_URL'])
	MongoMapper.connection = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
	MongoMapper.database = uri.path.gsub(/^\//, '')
else
	MongoMapper.database = 'flitter'
end

# From 1 to len times, get and add a random value from base 36 (a-z, 1-9) to ranStr
def random_string(len)
	ranStr = ""
	1.upto(len) { ranStr << rand(36).to_s(36) }	
	return ranStr
end

# User data & password hashing
class User
	include MongoMapper::Document

	key :login,		        String,		:length => (5..10), :unique => true
	key :firstlastname,		String,		:length => (2..30)
	key :hashPass, 			String
	key :email,		        String,		:length => (5..40), :required => true, :unique => true 
	key :salt,		        String
	
	timestamps!

	attr_accessor :login, :firstlastname, :email # R/W access
	# Make sure email contains an @
	validates_format_of :email, :with => /@/
	validates_format_of :login, :with => /[a-z]/

	validate :protected_names

	def protected_names
		protected = ["signup", "fbsignup", "login", "list", "logout"]
		if protected.include?(login)
			errors.add( :login, "That login name is protected, please choose another")		
		else
			
		end
	end

	def password=(pass)
		@password = pass
		self.salt = random_string(10) #unless self.salt
		self.hashPass = User.encrypt( @password, self.salt )
	end

	def self.encrypt(pass, salt)
		Digest::SHA1.hexdigest(pass + salt)
		
	end

	def self.authenticate(login, pass)
		u = User.first(:login => login)
		return nil if u.nil?
		return u if User.encrypt(pass, u.salt) == u.hashPass
		nil
	end

end

# User Flitts (Posts)
class Flitt

	include MongoMapper::Document

	key :user_id
	key :content, 			type: String, 	:required => true

	timestamps!

end
