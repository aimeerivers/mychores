class Testimonial < ActiveRecord::Base

validates_presence_of(:message)
validates_presence_of(:name)

end