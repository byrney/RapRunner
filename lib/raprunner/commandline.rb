
require 'optparse'
require 'pp'

module RapRunner

    def self.Run()

        options = Struct.new(:config, :group, :notifiers, :process_name, :dryrun).new

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
            opt.on('-h', '--help' , "Show this help") do |arg|
                puts opt.help()
                exit(0)
            end
            #opt.tail("Options will override arguments")
        end

        parser.parse!()

        def usage(parser, message)
            puts message
            puts parser.help()
            exit 1
        end

        location = options.config || ARGV[0]
        group = options.group || ARGV[1]
        usage(parser, "Must specify a configuration with --config") unless location
        usage(parser, "Nothing to run. Either --group or --process require") unless group || options.process_name

        loader = RapRunner::Loader.new(location)
        if(options.dryrun)
            pp loader.config
        else
            RapRunner::Runner.new(loader.config, group, options.process_name)
        end
    end
end
