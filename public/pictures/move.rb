

Dir.new(File.dirname($PROGRAM_NAME)).each do |f|
  next if f == '0000' || f == 'move.rb' || f == '..' || f == '.'

  new_name = sprintf("%04d", f.to_i)

  puts "Moving #{f} to #{new_name}"
  puts `mv #{f} 0000/#{new_name}`
end

