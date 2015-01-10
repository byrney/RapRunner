
module RapRunner

    class Monitor
        def initialize(io)
            @io = io
            @lock = Mutex.new
        end

        def write_nonblock(msg)
            @lock.synchronize {
                @io.write_nonblock(msg)
            }
        end

        def write(msg)
            @io.write(msg)
        end

        def close()
            @io.close()
        end
    end
end
