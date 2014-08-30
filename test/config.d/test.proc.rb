process "print-10-10m", "cd print && ruby print.rb 10 600" do |p|
    p.group('proc')
    p.group('all')
    p.colour = 'yellow'
    p.notify(/NOTIFY(.*)/)
end

process "print-5-1m", "ruby print.rb 5 60" do |p|
    p.group('proc')
    p.group('all')
    p.colour = :green
    p.notify(/NOTIFY(.*)/)
    p.dir = 'print'
    p.max_restarts = 3
end

process "exit success", "ruby exit_after.rb 20" do |p|
    p.group('all')
    p.max_restarts = 5
end

process "exit throws", "ruby throw_after.rb 10" do |p|
    p.group('all')
    p.max_restarts = 3
    p.colour = :cyan
end

process "exit throws 2", "ruby throw_after.rb 2" do |p|
    p.group('all')
    p.max_restarts = 5
    p.backoff_seconds = 1
    p.colour = :magenta
end
