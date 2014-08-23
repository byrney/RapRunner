
require 'eventmachine'
require 'date'
require 'pp'

def console(*args)
    printf("\n%s\t%s\n", DateTime.now(), args.join("\t"))
    STDOUT.flush
end

def debug(*args)
    printf("%s\t%s\n", DateTime.now(), args.join("\t"))
end

period = Integer(ARGV[0])
time = Integer(ARGV[1])

EM.run {
    EM.add_timer(time) { puts "stopping" ; EM.stop }
    EM.add_periodic_timer(period) { console "hello from print" }
#    EM.add_periodic_timer(period +1) { console "NOTIFY from print" }
}


