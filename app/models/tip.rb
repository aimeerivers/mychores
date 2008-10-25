class Tip < ActiveRecord::Base

  acts_as_taggable
  
  belongs_to(:person)
  
  validates_presence_of(:short_description)
  validates_length_of(:short_description, :maximum=>255)
  
  validates_presence_of(:full_description)
  
end
