require 'rainbow'

notifier(:screen) do |raw_line, name, matches|
    puts Rainbow("SCREEN:#{name}").bright + matches[1]
end

