require "./test/test_helper"

class SheetTest < Minitest::Test
  # NOTE: Many tests for the sheet class live in the test cases for various file formats

  def test_enumerable
    @workbook = Xsv::Workbook.open("test/files/excel2016.xlsx")

    first_row = @workbook.sheets[0].first
    assert_equal @workbook.sheets[0][0], first_row

    filtered_rows = @workbook.sheets[0].select { |r| r[1].to_i > 2 }
    assert_equal 2, filtered_rows.length
  end

  def test_empty
    @workbook = Xsv::Workbook.open("test/files/empty.xlsx")
    sheet = @workbook.sheets[0]
    sheet.parse_headers!

    assert_equal([], sheet.headers)
    assert_equal({}, sheet[0])
  end
end
