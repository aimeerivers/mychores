class List < ActiveRecord::Base

belongs_to(:team)
validates_associated(:team)

has_many(:tasks) # lists have tasks in the heirarchy

validates_presence_of(:name)
validates_length_of(:name, :maximum=>25)

end
