require 'active_record'

class User < ActiveRecord::Base
  has_many :emails
end

class AdminUser < User
end
