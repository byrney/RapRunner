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
            @config = config
            @input_ios = [STDIN]
            @monitors = [Monitor.new(STDOUT, false)]  # mute stdout in server mode
            @processes = {}
            if(name)
                notice( "Starting process [#{name}]")
                active_configs = config.processes.select{|h| h.name == name}
            else
                notice( "Starting group [#{group}]")
                active_configs = config.processes.select{|h| h.groups.include?(group)}
            end
            raise("Nothing to run in group [#{group}]") unless active_configs.length > 0
            @notifiers = std_notifiers().merge(config.notifiers || {})
            run(active_configs, server)
        end

        def run(active_configs, server)
            @processes = exec(active_configs)
            if(server)
                wait_server(@processes)
            else
                wait_and_read(@processes)
            end
        end

        def exec(active_configs)
            instances = {}
            active_configs.each do |c|
                cname = Color.send(c.colour, c.name)
                notice(("Running [#{c.command}] as [#{cname}]. Notify on #{c.notifies}"))
                pi = create_instance(c)
                raise("Failed to run [#{c.name}] -> #{c.command}") unless pi.alive?
                instances[c.name] = pi
            end
            return instances
        end

        def create_instance(process_config)
            pi = ProcessInstance.new(process_config, @notifiers, self)
            return pi.run_background()
        end

        def server_accept(server)
            loop {
                client = server.accept()
                @monitors << Monitor.new(client)
                @input_ios << client
                client.write("RapRunner: Connected\n")
            }
        end

        def wait_server(processes)
            port = 2000
            puts("Accepting monitor connections on #{port}")
            server = TCPServer.new("127.0.0.1", port)
            server_thread = Thread.new { server_accept(server) }
            wait_and_read(processes)
            puts "Shutting down"
            server_thread.kill()
            stop_instances(@processes.dup())
        end

        def stop_instances(instances)
            return unless instances
            instances.each_pair do |k, i|
                puts "stopping #{k}"
                i.stop()
            end
        end

        def wait_and_read(processes)
            quit = nil
            until(quit)
                inputs = Array.new(@input_ios)
                readable,_,errored = IO.select(inputs, nil, inputs, 2)
                readable && readable.each do |r|
                    begin
                        line = r.readline()
                    rescue Exception => e
                        @input_ios.delete(r)
                        r.close()
                        next
                    end
                    quit = control_action(r, line, processes)
                end
                errored && errored.each do |e|
                    ps = @input_ios.delete(e)
                    ps.closed?() || ps.close()
                end
            end
        end

        def control_action(requestio, line, processes)
            respio = (requestio == STDIN) ? STDOUT : requestio
            @monitors.each { |m| m.io == respio && m.mute = true }
            case line.strip()
            when "status"
                respio.write( summary(processes) )
            when "mon"
                @monitors.each { |m| m.io == respio && m.mute = false }
            #when ""
            when "shutdown"
                return true
            else
                respio.write("Unknown control action #{line}");
            end
            return nil
        end

        def summary(processes)
            body = []
            body << sprintf("%s%s%s", '=' * 30, '  status   ', '=' * 30)
            format = "%-10s%-15s%-20s%-20s%-30s"
            body << sprintf(format, 'pid', 'name', 'status', 'start', 'command')
            processes.each_pair do |name, pi|
                st = pi.start_time.strftime("%T") if pi.start_time
                body << sprintf(format,  pi.pid, pi.name, colour_status(pi.thread), st, pi.command)
            end
            body << sprintf("%s\n", '=' * 70)
            return  body.join("\n");
        end

        def monitor(message)
            current_monitors = Array.new(@monitors)
            current_monitors.each do |m|
                begin
                    m.write(message)
                rescue Exception, Errno::ECONNRESET
                    #@input_ios.delete(m.ios)
                    client = @monitors.delete(m)
                    if(client)
                        client.closed?() || client.close()
                    end
                end
            end
        end

        def notice(message)
            puts message
            monitor(message)
        end

        def log(process_name, process_colour, output)
            msg = Color.send(process_colour, process_name) + ":" + output
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

    end

end

if __FILE__ == $0
    location = ARGV[0]
    group = ARGV[1]
    loader = RapRunner.Loader.new(location)
    RapRunner.Runner.new(loader.config, group, nil)
end

