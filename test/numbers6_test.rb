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

  def test_numbers_sheet0
    skip "Implement row skipping to skip Numbers header"
    skip "Validate date types"
  end
end
