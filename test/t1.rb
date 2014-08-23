#!/usr/bin/env ruby
require 'raprunner'
location = ARGV[0]
group = ARGV[1]
loader = Loader.new(location)
Runner.new(loader.config, group)
