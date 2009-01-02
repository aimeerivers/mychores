DEFAULT_TASKS = [
  {:list => 'General', :task => 'Water plants', :due => 'today'},
  {:list => 'Living Room', :task => 'Plump cushions', :due => 'today'},
  {:list => 'General', :task => 'Put away things out of place', :due => 'tomorrow'},
  {:list => 'General', :task => 'Dust surfaces', :due => 'in 2 days'},
  {:list => 'General', :task => 'Laundry', :due => 'in 2 days'},
  {:list => 'General', :task => 'Sweep/vacuum floors', :due => 'in 3 days'},
  {:list => 'Bathroom', :task => 'Change towels', :due => 'in 4 days'},
  {:list => 'Bathroom', :task => 'Clean & scrub bath', :due => 'in 4 days'},
  {:list => 'Bathroom', :task => 'Clean toilet', :due => 'in 4 days'},
  {:list => 'Bedroom', :task => 'Change bed sheets', :due => 'in 5 days'},
  {:list => 'General', :task => 'Open windows', :due => 'in 5 days'},
  {:list => 'Kitchen', :task => 'Scrub & disinfect sink', :due => 'in 6 days'},
  {:list => 'Kitchen', :task => 'Wipe appliances', :due => 'in 6 days'},
  {:list => 'Kitchen', :task => 'Empty & clean bin', :due => 'in ~2 weeks'},
  {:list => 'Kitchen', :task => 'Clean cupboards & pantry', :due => 'in ~5 weeks'},
  {:list => 'Kitchen', :task => 'Clean oven thoroughly', :due => 'in ~2 months'},
  {:list => 'Living Room', :task => 'Clean television & stereo', :due => 'in ~3 months'},
  {:list => 'Bedroom', :task => 'Turn mattress', :due => 'in ~4 months'}
]

Then /^I should see a workload list showing the default tasks$/ do
  DEFAULT_TASKS.each do |task_def|
    response.should have_tag('tr') do
      with_tag('td', /^#{task_def[:list]}/)
      with_tag('td', /^#{task_def[:task]}/)
      with_tag('td', /#{task_def[:due]}\)$/)
    end
  end
end

Then /^I should see the default tasks on the hot map view$/ do
  DEFAULT_TASKS.each do |task_def|
    next if task_def[:task] == 'Clean oven thoroughly'
    next if task_def[:task] == 'Clean television & stereo'
    next if task_def[:task] == 'Turn mattress'
    response.should have_tag('a', "#{task_def[:list]}: #{task_def[:task]}")
  end
end


