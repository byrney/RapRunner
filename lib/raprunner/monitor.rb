
module RapRunner

    class Monitor
        def initialize(io, mute = false)
            @io = io
            @lock = Mutex.new
            @mute = mute
        end

        attr_reader :io
        attr_accessor :mute

        def write_nonblock(msg)
            return if mute
            @lock.synchronize {
                @io.write_nonblock(msg)
            }
        end

        def write(msg)
            return if mute
            @io.write(msg)
        end

        def close()
            @io.close()
        end
    end
end
