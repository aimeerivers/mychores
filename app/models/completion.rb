class Completion < ActiveRecord::Base

	belongs_to(:person) # a person may have completed ...
	belongs_to(:task) # ... a task

end
