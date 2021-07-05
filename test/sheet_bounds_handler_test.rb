require './test/test_helper'

class SheetBoundsHandlerTest < Minitest::Test
  def setup
    @workbook = Xsv::Workbook.open('test/files/excel2016.xlsx')
    @sheet = File.open('test/files/sheet1.xml')
  end

  def test_sheet_bounds
    rows, cols = Xsv::SheetBoundsHandler.get_bounds(@sheet, @workbook)

    assert_equal 4, rows
    assert_equal 8, cols
  end
end
