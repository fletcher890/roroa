class Admin < ActiveRecord::Base
	
	has_secure_password

	has_many :posts
	
	validates :email, presence: true, uniqueness: true, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  	validates :first_name, :last_name, :username, :access_level, :presence => true 

	ACCESS_LEVELS = ["admin", "editor"]

	validates_uniqueness_of :email, :username

	validates_presence_of :password, :on => :create
	
end 