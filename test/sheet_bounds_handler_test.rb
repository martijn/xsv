require "./test/test_helper"

class SheetBoundsHandlerTest < Minitest::Test
  def setup
    @workbook = Xsv.open("test/files/excel2016.xlsx")
    @sheet = File.open("test/files/sheet1.xml")
  end

  def test_sheet_bounds
    rows, cols = Xsv::SheetBoundsHandler.get_bounds(@sheet, @workbook)

    assert_equal 4, rows
    assert_equal 8, cols
  end

  def test_sheet_bounds_with_inline_strings_without_dimension
    sheet = File.open("test/files/inlineStr-no-dimension.xml")
    rows, cols = Xsv::SheetBoundsHandler.get_bounds(sheet, @workbook)

    assert_equal 3, rows
    assert_equal 2, cols
  end
end
