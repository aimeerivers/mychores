Then /^there should be (\d+) (\w+)s? in the database$/ do |number, model|
  model.classify.constantize.count.should == number.to_i
end