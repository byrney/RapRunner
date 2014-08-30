
class ProcessConfig

    COLOURS = [:black, :white, :green, :blue, :magenta, :yellow, :cyan]

    def self.Create(hash)
        c = ProcessConfig.new(hash[:name], hash[:cmd])
        c.colour = hash[:colour].to_sym if hash[:colour]
        c.groups = Array(hash[:groups])
        c.notify(hash[:notify]) if hash[:notify]
        return c
    end

    def initialize(name, command)
        @name = name
        @command = command
        @colour = :white
        @spawn_opts = {}
        @restarts = 1
        @backoff_seconds = 2
    end

    def to_s()
        sprintf("{ name: %s, command: %s, colour: %s, groups: %s, notifies: %s, spawn_opts %s }",
                @name, @command, @colour, @groups, @notifies, @spawn_opts)
    end

    def group(g)
        @groups ||= []
        @groups << g
    end

    def notify(n)
        @notifies ||= []
        @notifies << n
    end

    def colour=(colour)
        sym = colour.to_sym
        raise('Unknown colour [colour]') unless COLOURS.include?(sym)
        @colour = sym
    end

    def color=(c)
        self.colour = c
    end

    def dir=(d)
        @spawn_opts ||= {}
        @spawn_opts[:chdir] = d
    end

    attr_reader :colour

    attr_accessor :groups, :backoff_seconds, :notifies, :directory, :name, :command, :notifier, :spawn_opts, :max_restarts

end
