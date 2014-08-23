# Raprunner

For managing long-running processes

Have a whole bunch of processes to run and keep running?  RapRunner can host them and merege all the
output into a single window with different colours to tell them apart.

If a process dies RapRunner will restart it (up to maxrestart times) with a basic back-off mechanism
to avoid filling the terminal with errors.

If a process is configured with a 'notify' then you can get notified when certain text is output by the
process  (500, 404, Exception... etc)

While it's running you can hit return (or anything really..) to get the current status of the processes


## Installation

Add this line to your application's Gemfile:

    gem 'raprunner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install raprunner

## Usage

Add the raprunner bin to your path, or find out where it's installed...

### as a commandline tool ###

Create a simple runner file

	runner.rb

	#       name            commandline gets passed to the shell
	command = "echo 'information' ; sleep 20 ; echo 'ERROR' ; sleep 20 ; echo 'DONE' " 
	process("print-10-10m", command) do |p|
		p.group('proc')     								# add this to the 'proc' group
		p.group('all')										# and the all group
		p.colour = 'yellow'									# make the text yellow
		p.notify(/ERROR(.*)/)								# notify me if it prints ERROR
	end

	process "print-5-1m", "ruby print.rb 5 60" do |p|
		p.group('proc')
		p.group('all')
		p.colour = :green									# symbols or strings for colours
		p.notify("NOTIFY")									# plain string notify
		p.dir = 'subdir'									# change to this dir before run
		p.max_restarts = 3									# restart max 3 times. Default is 10
	end

Run it

	raprunner runner.rb all

if you pass a directory in place of a file then RapRunner will load all the files in that directory. Handy if you have a 
few. You can split them up into groups in this case using the group command

	group 'web' do
		process 'web1', '/path/to/tool' do |p|
			p.colour = :red
		end

		process 'web2', '/path/to/tool2' do |p|
			p.colour = :blue
			p.group 'bluestuff'		# this will be in web AND bluestuff groups
		end
	end

so that the processes within each file form a group.



### from code ###

	require 'raprunner'
	location = 'myprocesses.rb'
	group = 'servers'
	loader = Loader.new(location)
	Runner.new(loader.config, group)

## Contributing

1. Fork it ( http://github.com/byrney/raprunner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
