#! /usr/bin/env ruby
###!/opt/sensu/embedded/bin/ruby

require 'open-uri'
require 'json'

HOST = ARGV[0].to_s

END_POINT = "http://#{HOST}:4567/clients"
#BASIC_AUTH = {:http_basic_authentication => ['admin', 'supersecret']}

#response = open(END_POINT, BASIC_AUTH)
response = open(END_POINT)

clients = JSON.parse(response.read)

clients.each do |client|
  puts client['name']
end
