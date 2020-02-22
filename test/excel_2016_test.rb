require "test_helper"

class Excel2016Test < Minitest::Test
  def setup
    @file = Xsv::Workbook.open("test/files/excel2016.xlsx")
  end

  def test_access_sheets_by_index
    refute_equal @file.sheets[0], @file.sheets[1]
    assert_nil @file.sheets[9]
  end

  def test_access_row_by_index
    assert_kind_of Array, @file.sheets[0][0]
  end

  def test_value_types
    assert_equal [
      "Foo", 2, 2.5, nil, Date.new(2020, 2, 20), "10:00", 4, 1.25,
    ], @file.sheets[0][1]
  end

  def test_hash_value_types
    @file.sheets[0].parse_headers!

    expected = { "Some strings" => "Foo", "Some integer numbers" => 2, "Some decimal numbers" => 2.5, "Some empty values" => nil, "Some dates" => Date.new(2020, 2, 20), "Some times" => "10:00", "Some integer calculations" => 4, "Some decimal calculations" => 1.25 }

    assert_equal expected, @file.sheets[0][0]
  end

  def test_fetch_all_columns
    @file.sheets[1][0].length == 4
  end

  def test_fetch_all_rows
    rows = 0

    @file.sheets[1].each_row do |row|
      rows += 1
    end

    assert_equal 6, rows
  end

  def test_fetch_skipped_row
    empty_row = @file.sheets[1][2]

    assert_equal [nil, nil, nil, nil], empty_row
  end

  def test_fetch_leading_null
    row = @file.sheets[1][4]

    assert_equal [nil, "Row with leading null"], row.first(2)
  end

  def test_hash_fetch_leading_null
    @file.sheets[1].parse_headers!

    row = @file.sheets[1][3]

    expected = { "Header cell A" => nil, "Header cell B" => "Row with leading null", nil => nil, "Header cell D" => "Row with leading null" }

    assert_equal expected, row
  end

  def test_fetch_trailing_null
    row = @file.sheets[1][5]

    assert_equal ["Row with trailing null", nil, nil], row.last(3)
  end

  def test_hash_fetch_trailing_null
    @file.sheets[1].parse_headers!

    row = @file.sheets[1][4]

    expected = { "Header cell A" => "Row with trailing null", "Header cell B" => "Row with trailing null", nil => nil, "Header cell D" => nil }

    assert_equal expected, row
  end

  def test_sheet_without_cells
    assert_equal [], @file.sheets[2][0]
  end

  def test_merged_rows_and_cells
    sheet = @file.sheets[3]

    assert_equal "Merged B-C", sheet[0][1]
    assert_nil sheet[0][2]
    assert_equal "Merged 2-3", sheet[1][0]
    assert_nil sheet[1][1]
  end

  def test_hidden_cells
    sheet = @file.sheets[3]

    assert_equal "Hidden E4", sheet[3][4]

    assert_equal ["A1", "Merged B-C", nil, "D", "Hidden E", "F"], sheet.headers
  end

  def test_hidden_sheet
    sheet = @file.sheets[4]

    assert_equal "I'm secret", sheet[0][0]
  end

  def test_inline_formats
    sheet = @file.sheets[4]

    assert_equal "This sharedString is split down the middle", sheet[2][0]
  end
end
