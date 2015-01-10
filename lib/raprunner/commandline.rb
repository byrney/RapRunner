
require 'optparse'
require 'pp'

module RapRunner

    def self.Parse(argv)

        options = Struct.new(:config, :group, :notifiers, :process_name, :dryrun, :server).new

        parser = OptionParser.new() do |opt|
            opt.banner = "Usage: #{File.basename($0)} [OPTIONS] CONFIG GROUP"
            opt.on('-c', '--config CONFIG', String, "File or directory of configuration") do |arg|
                options.config = arg
            end
            opt.on('-g', '--group GROUP', String, "Group name to start") do |arg|
                options.group = arg
            end
            opt.on('-p', '--process NAME', String, "Process name to start") do |arg|
                options.process_name = arg
            end
            opt.on('-n', '--dry-run', "Dry Run. Just dump the config") do |arg|
                options.dryrun = true
            end
            opt.on('-s', '--server', "Run as TCP server") do |arg|
                options.server = true
            end
            opt.on('-h', '--help' , "Show this help") do |arg|
                puts opt.help()
                exit(0)
            end
            #opt.tail("Options will override arguments")
        end

        parser.parse!(argv)

        def usage(parser, message)
            puts message
            puts parser.help()
            exit 1
        end

        # these for backward compatability
        options.config ||= argv[0]
        options.group ||= argv[1]
        usage(parser, "Must specify a configuration with --config") unless options.config
        usage(parser, "Nothing to run. Either --group or --process require") unless options.group || options.process_name
        return options
    end

    def self.Start(argv)
        options = self.Parse(argv)
        loader = RapRunner::Loader.new(options.config)
        if(options.dryrun)
            pp loader.config
        else
            RapRunner::Runner.new(loader.config, options.group, options.process_name, options.server)
        end
    end
end
