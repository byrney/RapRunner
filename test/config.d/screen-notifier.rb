require 'term/ansicolor'

notifier(:screen) do |raw_line, name, matches|

    #puts Rainbow("SCREEN:#{name}").bright + matches[1]
    c = Term::ANSIColor;
    puts c.red { c.bold { "SCREEN:#{name}" } } + matches[1]
end

