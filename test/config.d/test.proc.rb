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

