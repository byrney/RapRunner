#!/usr/bin/env ruby

$: << "."
require 'pry'
require 'terminal-notifier'
require 'date'
require 'open3'
require 'socket'
require 'raprunner/config'
require 'raprunner/loader'
require 'raprunner/color'
require 'raprunner/instance'
require 'raprunner/monitor'

module RapRunner

    class Runner

        def initialize(config, group, name, server)
            @monitors = []
            @monitors << STDOUT unless server
            if(name)
                notice( "Starting process [#{name}]")
                active = config.processes.select{|h| h.name == name}
            else
                notice( "Starting group [#{group}]")
                active = config.processes.select{|h| h.groups.include?(group)}
            end
            raise("Nothing to run in group [#{group}]") unless active.length > 0
            @notifiers = std_notifiers().merge(config.notifiers || {})
            run(active, server)
        end

        def run(active, server)
            @processes = exec(active)
            if(server)
                wait_server(@processes, [STDIN])
            else
                wait_and_read(@processes, [STDIN])
            end
        end

        def exec(commands)
            threads = {}
            commands.each do |c|
                cname = Color.send(c.colour, c.name)
                notice(("Running [#{c.command}] as [#{cname}]. Notify on #{c.notifies}"))
                thread,pi = run_background_process(c)
                raise("Failed to run [#{c.name}] -> #{c.command}") unless thread.alive?
                threads[thread] = pi
            end
            return threads
        end

        def run_background_process(process_config)
            pi = ProcessInstance.new(process_config, @notifiers, self)
            thread = Thread.new do
                run_process(pi, process_config)
            end
            return thread, pi
        end

        def run_process(pi, process_config)
            loop do
                exit_status = pi.run()
                pi.restarts += 1
                restart_time = exit_status == 0 ? 0 : pi.backoff_seconds ** pi.restarts
                on_process_exit(process_config.name, exit_status, restart_time, pi.restarts, pi.max_restarts)
                sleep(pi.backoff_seconds ** pi.restarts)
                r = pi.restarts
                m = pi.max_restarts
                if(r < m)
                    notice("Restart [#{pi.restarts} of #{pi.max_restarts}]: #{process_config.name}")
                else
                    notice("Not restarting [#{pi.restarts} of #{pi.max_restarts}]: #{process_config.name}")
                    break
                end
            end
        rescue Exception => e
            pp e
            pp e.backtrace
        end

        def summary(processes)
            body = []
            body << sprintf("%s%s%s", '=' * 30, '  status   ', '=' * 30)
            format = "%-10s%-15s%-20s%-20s%-30s"
            body << sprintf(format, 'pid', 'name', 'status', 'start', 'command')
            processes.each_pair do |thread, pi|
                st = pi.start_time.strftime("%T") if pi.start_time
                body << sprintf(format,  pi.pid, pi.name, colour_status(thread), st, pi.command)
            end
            body << sprintf("%s\n", '=' * 70)
            return  body.join("\n");
        end

        def wait_and_read(processes, input_ios)
            process_threads = processes.keys()
            while(process_threads.any? {|t| t.alive?})
                rs,_,_ = IO.select(input_ios, nil, nil, 5)
                if(rs)
                    rs.first.readline
                    puts summary(processes)
                end
            end
        rescue EOFError
            monitor("Bye")
        end

        def server_accept(server)
            loop {
                client = server.accept()
                @monitors << Monitor.new(client)
                client.write("RapRunner: Connected\n")
            }
        end

        def wait_server(processes, ios)
            port = 2000
            puts("Accepting monitor connections on #{port}")
            server = TCPServer.new("127.0.0.1", port)
            Thread.new { server_accept(server) }
            wait_and_read(processes, ios)
        end

        def monitor(message)
            current_monitors = Array.new(@monitors)
            current_monitors.each do |m|
                begin
                    m.write(message)
                rescue IOError => e
                    pp e
                    client = @monitors.delete(m)
                    client.close()
                end
            end
        end

        def notice(message)
            puts message
            monitor(message)
        end
        def log(process_name, output)
            pi = @processes.find { |k,v| v.name == process_name }[1]
            msg = Color.send(pi.colour, process_name) + ":" + output
            monitor(msg)
        end

        def std_notifiers()
            notifiers = {}
            if(TerminalNotifier.available?)
                osx_notify = lambda do |raw_line, name, matches|
                    message = matches[1]
                    message ||= raw_line
                    TerminalNotifier.notify(message, :title => name, :subtitle => matches[0], :group => name)
                end
                notifiers[:osx] = osx_notify
            end
            console_notify = lambda do |raw_line, name, matches|
                message = matches[1]
                message ||= raw_line
                puts Color.red(name) + ":" + Color.red(message)
            end
            notifiers[:console] = console_notify
            return notifiers
        end

        def on_process_exit(name, exit_status, restart_time, restart, max_restarts)
            msg_restart = restart >= max_restarts ? "Will not be restarted" : "Restart in #{restart_time} seconds"
            if(exit_status == 0)
                call_notify("Process [#{name}] exited", name, ["Exit:", "#{name} exited. #{msg_restart}"])
            else
                call_notify("Process [#{name}] failed", name, ["Fail:", "#{name} failed with status #{exit_status}. #{msg_restart} "])
            end
        end

        def call_notify(raw_line, name, matches)
            return unless @notifiers
            @notifiers.each_pair do |k, n|
                n.call(raw_line, name, matches)
            end
        end

        def error(text)
            Color.red(text)
        end

        def colour_status(thread)
            status= thread.status
            case(status)
            when 'sleep'
                Color.green('running')
            when false
                Color.red('finished')
            when nil
                Color.red('exception')
            end
        end

        def all_finished?(threads)
            running = threads.any? {|t| t.alive? }
            return !running
        end

    end

end
if __FILE__ == $0
    location = ARGV[0]
    group = ARGV[1]
    loader = RapRunner.Loader.new(location)
    RapRunner.Runner.new(loader.config, group, nil)
end

