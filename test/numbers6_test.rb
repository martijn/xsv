require "test_helper"

class Numbers6Test < Minitest::Test
  def test_detect_sheet_bounds
    @workbook = Xsv::Workbook.open("test/files/numbers6-default.xlsx")

    sheet = @workbook.sheets[0]

    assert_equal 4, sheet[0].length
  end

  def test_fetch_all_rows
    @workbook = Xsv::Workbook.open("test/files/numbers6-default.xlsx")

    rows = 0

    @workbook.sheets[0].each_row do |row|
      rows += 1
    end

    assert_equal 12, rows
  end

  def test_numbers_sheet0
    @workbook = Xsv::Workbook.open("test/files/numbers6-worksheets.xlsx")

    sheet = @workbook.sheets[0]

    assert_equal ["Row 2", "Numbers", "6.2.1", nil, nil, nil, nil], sheet[3]
  end

  def test_numbers_types
    @workbook = Xsv::Workbook.open("test/files/numbers6-worksheets.xlsx")

    sheet = @workbook.sheets[1]
    sheet.row_skip = 1

    assert_equal 1234.5678, sheet[3][1]

    sheet.parse_headers!

    expected = { "Text" => "Hi there", "Number" => 1234, nil => nil, "Date" => Date.new(2020, 2, 20), "Time" => "13:00", "DateTime" => Time.new(2020, 2, 20, 13, 00) }

    assert_equal expected, sheet[0]
  end

  def test_row_skip
    @workbook = Xsv::Workbook.open("test/files/numbers6-worksheets.xlsx")

    sheet = @workbook.sheets[1]
    sheet.row_skip = 1

    assert_equal "Text", sheet[0][0]
  end

  def test_fetch_all_rows_with_row_skip
    @workbook = Xsv::Workbook.open("test/files/numbers6-default.xlsx")

    rows = 0

    @workbook.sheets[1].row_skip = 1
    @workbook.sheets[1].parse_headers!

    @workbook.sheets[1].each_row do |row|
      rows += 1
    end

    assert_equal 2, rows
  end
end
