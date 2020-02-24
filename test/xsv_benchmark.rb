require "test_helper"
require "minitest/benchmark"

class XsvBenchmark < Minitest::Benchmark
  def bench_row_access
    zip = File.read("test/files/10k-sheet.xlsx")
    assert_performance_linear do |n|
      x = Xsv::Workbook.open(zip)
      x.sheets[0][n]
    end
  end
end
