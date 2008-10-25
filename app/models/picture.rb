class Picture < ActiveRecord::Base

  has_attachment :storage => :file_system, :content_type => :image, :max_size => 90.kilobytes
  validates_as_attachment
  
  belongs_to(:person) # the person who uploaded it
  
end
