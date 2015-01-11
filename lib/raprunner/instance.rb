module RapRunner

    class ProcessInstance

        attr_reader :name, :command
        attr_accessor :restarts
        attr_reader :pid, :last_exit_status, :thread, :start_time

        def initialize(config, notifiers, output_logger)
            @config = config
            @name = @config.name
            @command = @config.command
            @output_colour = config.colour
            @backoff_seconds = config.backoff_seconds
            @max_restarts = @config.max_restarts || 10
            @restarts = 0
            @pid = nil
            @start_time  = nil
            @notifiers = notifiers
            @thread = nil
            @output_logger = output_logger
        end

        def call_notify(raw_line, name, matches)
            return unless @notifiers
            @notifiers.each_pair do |k, n|
                n.call(raw_line, name, matches)
            end
        end

        def alive?()
            @thread.alive?()
        end

        def log( message)
            @output_logger.log(@config.name, @config.colour, message)
        end

        def run()
            cmd = @config.command
            name = @config.name
            notify = @config.notifies.first  if @config.notifies #  not supported multiple yet
            spawn_opts = @config.spawn_opts.clone()  # popen modifies this
            @start_time = DateTime.now()
            Open3.popen2e(cmd, spawn_opts) do |stdin, stream, thread|
                @pid = thread.pid
                until (raw_line = stream.gets).nil? do
                    if(raw_line.rstrip.length > 0)
                        match = notify && raw_line.match(notify)
                        match && call_notify(raw_line, name, match)
                        log(raw_line)
                    end
                end
                @last_exit_status = thread.value.exitstatus
            end
            #onexit(name, @last_exit_status)
            return @last_exit_status
        end

        def run_with_restarts(process_config)
            loop do
                exit_status = run()
                @restarts += 1
                restart_time = exit_status == 0 ? 0 : @backoff_seconds ** @restarts
                on_process_exit(process_config.name, exit_status, restart_time, @restarts, @max_restarts)
                sleep(backoff_seconds ** @restarts)
                if(@restarts < @max_restarts)
                    @output_logger.notice("Restart [#{@restarts} of #{@max_restarts}]: #{process_config.name}")
                else
                    @output_logger.notice("Not restarting [#{@restarts} of #{@max_restarts}]: #{process_config.name}")
                    break
                end
            end
        rescue Exception => e
            pp e
            pp e.backtrace
        end

        def run_background()
            Thread.abort_on_exception = true
            run_thread = Thread.new do
                run_with_restarts(@config.dup())
            end
            @thread = run_thread
            return self
        end

        def on_process_exit(name, exit_status, restart_time, restart, max_restarts)
            msg_restart = restart >= max_restarts ? "Will not be restarted" : "Restart in #{restart_time} seconds"
            if(exit_status == 0)
                call_notify("Process [#{name}] exited", name, ["Exit:", "#{name} exited. #{msg_restart}"])
            else
                call_notify("Process [#{name}] failed", name, ["Fail:", "#{name} failed with status #{exit_status}. #{msg_restart} "])
            end
        end

    end

end
