
STDOUT.sync = true
t = Integer(ARGV[0])
puts "Starting. Will raise error after #{t} seconds"
sleep(t)
puts "Throw"
raise("Raising exception")



