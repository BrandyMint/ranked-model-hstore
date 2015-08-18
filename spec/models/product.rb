require 'active_record'

class Product < ActiveRecord::Base
  include ProductSortableByCategory
end
