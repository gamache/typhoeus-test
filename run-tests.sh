#!/bin/bash

#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=0' > ruby-sleep-0000.json
#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=25' > ruby-sleep-0025.json
#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=50' > ruby-sleep-0050.json
#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=100' > ruby-sleep-0100.json
#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=200' > ruby-sleep-0200.json
#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=400' > ruby-sleep-0400.json
#ruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=1000' > ruby-sleep-1000.json

rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=0' > jruby-sleep-0000.json
rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=25' > jruby-sleep-0025.json
rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=50' > jruby-sleep-0050.json
rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=100' > jruby-sleep-0100.json
rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=200' > jruby-sleep-0200.json
rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=400' > jruby-sleep-0400.json
rvm jruby do jruby typhoeus-test.rb GET 'http://52.25.215.72/?sleep=1000' > jruby-sleep-1000.json
