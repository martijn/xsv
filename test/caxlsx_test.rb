require "./test/test_helper"

class CaxlsxTest < Minitest::Test
  def setup
    @file = Xsv::Workbook.open("test/files/caxlsx.xlsx")
  end

  # https://github.com/martijn/xsv/issues/29
  def test_return_rows
    assert_equal [1], @file.sheets[0][0]
  end
end
