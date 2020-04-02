require "test_helper"

class SheetTest < Minitest::Test
  # Note: Many tests for the sheet class live in the test cases for various file formats
  def setup
    @workbook = Xsv::Workbook.open("test/files/excel2016.xlsx")
  end

  def test_enumerable
    first_row = @workbook.sheets[0].first
    assert_equal @workbook.sheets[0][0], first_row

    filtered_rows = @workbook.sheets[0].select { |r| r[1].to_i > 2 }
    assert_equal 2, filtered_rows.length
  end
end
