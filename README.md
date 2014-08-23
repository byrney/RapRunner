# Raprunner

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'raprunner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install raprunner

## Usage

Add the raprunner bin to your path, or find out where it's installed...

Create a simple runner file

	runner.rb

	#       name            commandline gets passed to the shell
	process "print-10-10m", "echo 'information' ; sleep 20 ; echo 'ERROR' ; sleep 20 ; echo 'DONE' " do |p|
		p.group('proc')     											# add this to the 'proc' group
		p.group('all')													# and the all group
		p.colour = 'yellow'												# make the text yellow
		p.notify(/ERROR(.*)/)											# notify me if it prints ERROR
	end

	process "print-5-1m", "ruby print.rb 5 60" do |p|
		p.group('proc')
		p.group('all')
		p.colour = :green
		p.notify(/NOTIFY(.*)/)
		p.dir = 'print'													# change to this dir before run
		p.max_restarts = 3												# restart max 3 times. Default is 10
	end

Run it

	raprunner runner.rb all


## Contributing

1. Fork it ( http://github.com/<my-github-username>/raprunner/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
