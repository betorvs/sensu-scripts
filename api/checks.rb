#! /usr/bin/env ruby
###!/opt/sensu/embedded/bin/ruby

require 'open-uri'
require 'json'

HOST = ARGV[0].to_s

END_POINT = "http://#{HOST}:4567/checks"
#BASIC_AUTH = {:http_basic_authentication => ['admin', 'supersecret']}

#response = open(END_POINT, BASIC_AUTH)
response = open(END_POINT)

checks = JSON.parse(response.read)

checks.each do |check|
  puts "check: #{check['name']} -> deploy by #{check['subscribers']} and handler by #{check['handlers']}"
end
