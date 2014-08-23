#!/usr/bin/env ruby

$: << "."
require 'open3'
require 'rainbow'
require 'json'
require 'pry'
require 'terminal-notifier'
require 'date'
require 'raprunner/config'
require 'raprunner/loader'

class ProcessInstance
    def initialize(config, notifiers)
        @config = config
        @pid = nil
        @restarts = 0
        @start_time  = nil
        @notifiers = notifiers
    end

    def name()
        @config.name
    end

    def command()
        @config.command
    end

    def max_restarts()
        @config.max_restarts || 10
    end

    attr_accessor :restarts
    attr_reader :pid
    attr_reader :start_time

    def call_notify(raw_line, name, matches)
        return unless @notifiers
        puts "NOTIFY"
        @notifiers.each_pair do |k, n|
            n.call(raw_line, name, matches)
        end
    end

    def run()
        cmd = @config.command
        name = @config.name
        colour = @config.colour
        notify = @config.notifies.first  #  not supported multiple yet
        spawn_opts = @config.spawn_opts.clone()  # popen modifies this
        @start_time = DateTime.now()
        Open3.popen2e(cmd, spawn_opts) do |stdin, stream, thread|
            @pid = thread.pid
            until (raw_line = stream.gets).nil? do
                if(raw_line.rstrip.length > 0)
                    match = notify && raw_line.match(notify)
                    match && call_notify(raw_line, name, match)
                    puts Rainbow(name).color(colour) + ":" + raw_line
                end
            end
        end
        call_notify("Process [#{name}] exited", name, ["Exit:", "#{name} exited"])
        # puts Rainbow(name).color(colour) + ":" + error( "Exited: #{cmd}" )
    end

    attr_reader :config
end

class Runner

    def initialize(config, group)
        puts "Starting group [#{group}]"
        active = config.processes.select{|h| h.groups.include?(group)}
        raise("Nothing to run in group [#{group}]") unless active.length > 0
        osx_notify = lambda do |raw_line, name, matches|
            message = matches[1]
            message ||= raw_line
            TerminalNotifier.notify(message, :title => name, :subtitle => matches[0], :group => name)
        end
        console_notify = lambda do |raw_line, name, matches|
            message = matches[1]
            message ||= raw_line
            puts Rainbow(name).color(:red).bright() + ":" + Rainbow(message).color(:red).bright()
        end
        std_notifiers = { :osx => osx_notify, :console => console_notify }
        @notifiers = std_notifiers.merge(config.notifiers || {})
        run(active)
    end

    def run(active)
        processes = exec(active)
        wait_and_read(processes, STDIN)
    end

    def error(text)
        Rainbow(text).red
    end

    def run_background(process_config)
        pi = ProcessInstance.new(process_config, @notifiers)
        thread = Thread.new do
            begin
            loop do
                pi.run()
                sleep(pi.restarts ** 3)
                pi.restarts += 1
                r = pi.restarts
                m = pi.max_restarts
                if(r < m)
                    puts "Restart [#{pi.restarts} of #{pi.max_restarts}]: #{process_config.name}"
                else
                    puts "Not restarting [#{pi.restarts} of #{pi.max_restarts}]: #{process_config.name}"
                    break
                end
            end
            rescue Exception => e
                pp e
                pp e.backtrace
            end
        end
        return thread, pi
    end

    def colour_status(thread)
        status= thread.status
        case(status)
        when 'sleep'
            Rainbow('running').color(:green)
        when false
            Rainbow('finished').color(:red)
        when nil
            Rainbow('exception').color(:red)
        end
    end

    def exec(commands)
        threads = {}
        commands.each do |c|
            notify = c.notifies.first
            cname = Rainbow(c.name).color(c.colour)
            puts("Running [#{c.command}] as [#{cname}]. Notify on #{notify}")
            thread,pi = run_background(c)
            raise("Failed to run [#{c.name}] -> #{c.command}") unless thread.alive?
            threads[thread] = pi
        end
        return threads
    end

    def all_finished?(threads)
        running = threads.any? {|t| t.alive? }
        return !running
    end

    def wait_and_read(processes, input_io)
        process_threads = processes.keys()
        while(process_threads.any? {|t| t.alive?})
            rs,_,_ = IO.select([input_io], nil, nil, 5)
            if(rs)
                rs.first.readline
                printf("%s%s%s\n", '=' * 30, '  status   ', '=' * 30)
                format = "%-10s%-15s%-20s%-20s%-30s\n"
                printf(format, 'pid', 'name', 'status', 'start', 'command')
                processes.each_pair do |thread, pi|
                    st = pi.start_time.strftime("%T") if pi.start_time
                    printf(format,  pi.pid, pi.name, colour_status(thread), st, pi.command)
                end
                printf("%s\n", '=' * 70)
            end
        end
    rescue EOFError
        puts "Bye"
    end

end

if __FILE__ == $0
    location = ARGV[0]
    group = ARGV[1]
    loader = Loader.new(location)
    Runner.new(loader.config, group)
end

