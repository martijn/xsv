#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source "https://rubygems.org"

  gemspec
  gem "benchmark-memory"
  gem "benchmark-perf"
end

def bench_perf(sheet)
  result = Benchmark::Perf.cpu(repeat: 5) do
    sheet.each do |row|
      row.each do |cell|
        cell
      end
    end
  end

  puts "Performance benchmark: #{result.avg}s avg #{result.stdev}s stdev"
end

def bench_mem(sheet)
  Benchmark.memory do |bm|
    bm.report do
      sheet.each do |row|
        row.each do |cell|
          cell
        end
      end
    end
  end
end

file = File.read("test/files/10k-sheet.xlsx")

workbook = Xsv::Workbook.open(file)

puts "--- ARRAY MODE ---"

bench_perf(workbook.sheets[0])
bench_mem(workbook.sheets[0])

puts "\n--- HASH MODE ---"

workbook.sheets[0].parse_headers!

bench_perf(workbook.sheets[0])
bench_mem(workbook.sheets[0])
