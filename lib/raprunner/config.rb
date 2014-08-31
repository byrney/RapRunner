require 'raprunner/process_config'

module RapRunner
    class DSL

        def getbinding()
            binding
        end

        def group(g, &block)
            @current_group = g
            if(block_given?)
                yield self
            end
            @current_group = nil
        end

        def process(name, commandline, &block)
            @processes ||= []
            p = ProcessConfig.new(name, commandline)
            p.group(@current_group) if @current_group
            if(block_given?)
                yield p
            end
            @processes << p
        end

        def notifier(name, &block)
            p "adding notifier #{name}"
            @notifiers ||= {}
            @notifiers[name] = block
            pp @notifiers
        end

        attr_accessor :processes, :notifiers

    end

    class Configuration

        attr_accessor :processes, :notifiers

        def load_json(filename)
            options = JSON.parse(File.read(filename), :symbolize_names => true)
            procs = Array.new(options.length) do |index|
                ProcessConfig.Create(options[index])
            end
            @processes ||= []
            @processes.concat(procs)
        end

        def load(filename)
            content = File.read(filename)
            run(content)
        end

        def run(content)
            @processes ||= []
            @notifiers ||= {}
            cfg = DSL.new()
            eval(content, cfg.getbinding)
            @processes.concat(Array(cfg.processes))
            if(cfg.notifiers)
                @notifiers.merge!(cfg.notifiers) {|key, oldv, newv| puts "Warning: replacing notifier #{key}" ; newv}
            end
        end

        def to_s()
            s = '['
            @processes && @processes.each do |p|
                s+= p.to_s
            end
            s += ']'
        end

    end
end

if __FILE__ == $0
    ev = RapRunner.Configuration.new()
    ev.load(ARGV[0])
    puts ev
end

