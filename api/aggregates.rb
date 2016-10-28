#! /usr/bin/env ruby
###!/opt/sensu/embedded/bin/ruby

require 'open-uri'
require 'json'

HOST = ARGV[0].to_s

END_POINT = "http://#{HOST}:4567/aggregates"
#BASIC_AUTH = {:http_basic_authentication => ['admin', 'supersecret']}

#response = open(END_POINT, BASIC_AUTH)
response = open(END_POINT)

aggregates = JSON.parse(response.read)

aggregates.each do |list|
  puts list['name']
end
