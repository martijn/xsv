require './test/test_helper'
require 'minitest/benchmark'

class XsvBenchmark < Minitest::Benchmark
  def setup
    return true if defined? $warmed_up

    zip = File.read('test/files/10k-sheet.xlsx')
    5.times { Xsv::Workbook.open(zip).sheets[0].each { nil } }
    $warmed_up = true
  end

  def bench_row_access
    zip = File.read('test/files/10k-sheet.xlsx')
    x = Xsv::Workbook.open(zip)
    assert_performance_linear 0.001 do |n|
      x.sheets[0][n]
    end
  end

  def bench_iterate_hash
    zip = File.read('test/files/10k-sheet.xlsx')
    x = Xsv::Workbook.open(zip)
    x.sheets[0].parse_headers!

    assert_performance_linear 0.001 do |n|
      x.sheets[0].each_with_index do |row, i|
        row['A1']
        break if i == n
      end
    end
  end
end
