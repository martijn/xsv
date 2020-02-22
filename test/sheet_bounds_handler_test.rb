require "test_helper"

class SheetBoundsHandlerTest < Minitest::Test
  def setup
    @sheet = File.open("test/files/sheet1.xml")
  end

  def test_sheet_bounds
    rows, cols = Xsv::SheetBoundsHandler.get_bounds(@sheet)

    assert_equal 4, rows
    assert_equal 8, cols
  end
end
