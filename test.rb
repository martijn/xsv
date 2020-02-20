#!/usr/bin/ruby

require 'bundler'
Bundler.setup
Bundler.require

x = Xsv::File.new("bam.xlsx")

puts ":)"

s = x.sheets[0]

#s.parse_headers!

puts "row 1"
puts s[1].inspect
puts "row 0"
puts s[0].inspect

x.sheets[0].each_row do |row|
  puts row.inspect
end
