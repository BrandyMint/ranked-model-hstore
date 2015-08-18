#require 'rubygems'
require 'bundler/setup'
Bundler.require
#require 'pry'
#require 'factory_girl'
#require 'pg'
require './lib/product_sortable_by_category'
require './spec/models/product'

ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :database => 'ranked_test'
)


