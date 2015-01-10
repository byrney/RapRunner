module RapRunner

    class ProcessInstance
        def initialize(config, notifiers, output_logger)
            @config = config
            @pid = nil
            @restarts = 0
            @start_time  = nil
            @notifiers = notifiers
            @output_logger = output_logger
            @colour = config.colour
        end

        def name()
            @config.name
        end

        def command()
            @config.command
        end

        def backoff_seconds()
            @config.backoff_seconds
        end

        def max_restarts()
            @config.max_restarts || 10
        end

        attr_accessor :restarts
        attr_reader :pid, :last_exit_status
        attr_reader :start_time, :colour

        def call_notify(raw_line, name, matches)
            return unless @notifiers
            @notifiers.each_pair do |k, n|
                n.call(raw_line, name, matches)
            end
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
                        @output_logger.log(name, raw_line)
                    end
                end
                @last_exit_status = thread.value.exitstatus
            end
            #onexit(name, @last_exit_status)
            return @last_exit_status
        end

        attr_reader :config
    end

end
