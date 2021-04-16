require "./test/test_helper"

# Test for miscellaneous files found in the wild

class MiscTest < Minitest::Test
  def test_complex_number
    @file = Xsv::Workbook.open("test/files/complex.xlsx")

    row = @file.sheets[0][1]

    assert_equal 0.001, row[1]
    assert_equal 0.01, row[2]
    assert_equal 0.1, row[3]
  end
end
