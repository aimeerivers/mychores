class Testimonial < ActiveRecord::Base

  validates_presence_of(:message)
  validates_presence_of(:name)
  
  default_scope :order => 'id DESC'

  named_scope :approved, :conditions => {:approved => true}
    
  named_scope :random, :conditions => {:approved => true}, :offset => rand(self.approved.count), :limit => 1

end