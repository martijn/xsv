require "test_helper"

class SheetRowsHandlerTest < Minitest::Test
  def setup
    # Note: sheet1.xml comes from excel2016.xlsx
    @workbook = Xsv::Workbook.open("test/files/excel2016.xlsx")
    @sheet = File.open("test/files/sheet1.xml")
  end

  def test_parser_array_mode
    empty_row = [nil] * 7

    rows = []
    handler = Xsv::SheetRowsHandler.new(:array, empty_row, @workbook, 0, 99999) do |row|
      rows << row
    end

    Ox.sax_parse(handler, @sheet)

    assert_equal 4, rows.length
    assert_equal "Some strings", rows[0][0]
    assert_equal 2.5, rows[1][2]
    assert_equal "15:25", rows[3][5]
  end

  def test_parser_hash_mode
    empty_row = { "Some strings" => nil, "Some integer numbers" => nil, "Some decimal numbers" => nil, "Some empty values" => nil, "Some dates" => nil, "Some times" => nil, "Some integer calculations" => nil, "Some decimal calculations" => nil }

    rows = []
    handler = Xsv::SheetRowsHandler.new(:hash, empty_row, @workbook, 0, 99999) do |row|
      rows << row
    end

    Ox.sax_parse(handler, @sheet)

    assert_equal 3, rows.length
    assert_equal "Foo", rows[0]["Some strings"]
    assert_equal 2.5, rows[0]["Some decimal numbers"]
    assert_equal "15:25", rows[2]["Some times"]
  end
end
