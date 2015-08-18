class Product < ActiveRecord::Base
  include ProductSortableByCategory
end
