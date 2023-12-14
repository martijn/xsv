require "./test/test_helper"

class SheetRowsHandlerTest < Minitest::Test
  def setup
    # Note: sheet1.xml comes from excel2016.xlsx
    @workbook = Xsv.open("test/files/excel2016.xlsx")
    @sheet = File.open("test/files/sheet1.xml")
  end

  def test_parser_array_mode
    empty_row = [nil] * 7

    rows = []
    handler = Xsv::SheetRowsHandler.new(:array, empty_row, @workbook, 0, 99999) do |row|
      rows << row
    end

    handler.parse(@sheet)

    assert_equal 5, rows.length
    assert_equal "Some strings", rows[0][0]
    assert_equal 2.5, rows[1][2]
    assert_equal "15:25", rows[3][5]
  end

  def test_parser_hash_mode
    empty_row = {"Some strings" => nil, "Some integer numbers" => nil, "Some decimal numbers" => nil, "Some empty values" => nil, "Some dates" => nil, "Some times" => nil, "Some integer calculations" => nil, "Some decimal calculations" => nil}

    rows = []
    handler = Xsv::SheetRowsHandler.new(:hash, empty_row, @workbook, 0, 99999) do |row|
      rows << row
    end

    handler.parse(@sheet)

    assert_equal 4, rows.length
    assert_equal "Foo", rows[0]["Some strings"]
    assert_equal 2.5, rows[0]["Some decimal numbers"]
    assert_equal "15:25", rows[2]["Some times"]
  end

  # Make sure row skipping works correctly with different types of empty rows
  def test_skip_empty_rows
    @sheet = File.read("test/files/empty-row-skip.xml")

    rows = []

    collector = proc do |row|
      rows << row
    end

    first_columns = ["0", "1", nil, nil, "2"]

    6.times do |row_skip|
      rows = []
      handler = Xsv::SheetRowsHandler.new(:array, ([nil] * 10), @workbook, row_skip, 6, &collector)
      handler.parse(@sheet)
      assert_equal first_columns[row_skip..], rows.map(&:first)
    end
  end

  def test_inlinestr_text
    @sheet = File.read("test/files/inlineStr.xml")

    rows = []

    collector = proc do |row|
      rows << row
    end

    handler = Xsv::SheetRowsHandler.new(:array, ([nil] * 10), @workbook, 0, 6, &collector)
    handler.parse(@sheet)

    assert_equal "This is Text", rows[0][0]
  end

  def test_special_types
    rows = []
    handler = Xsv::SheetRowsHandler.new(:array, [], @workbook, 0, 99999) do |row|
      rows << row
    end

    handler.parse(@sheet)

    # B4 = N/A
    assert_nil rows[3][1]
    # E4 = formatted number
    assert_equal 4.999, rows[3][2]
    # A5 = true
    assert rows[4][0]
    # B5 = false
    refute rows[4][1]
  end

  def test_unknown_type
    handler = Xsv::SheetRowsHandler.new(:array, [], @workbook, 0, 99999) {}

    data = @sheet.read
    data.gsub! "t=\"s\"", "t=\"xyz\""

    assert_raises Xsv::Error, /unknown column type/ do
      handler.parse(data)
    end
  end

  def test_column_without_r_array
    @sheet = File.read("test/files/column-without-r.xml")

    rows = []

    collector = proc do |row|
      rows << row
    end

    handler = Xsv::SheetRowsHandler.new(:array, ([nil] * 2), @workbook, 0, 6, &collector)
    handler.parse(@sheet)

    assert_equal ["Some strings", "Foo"], rows[0]
    assert_equal ["Bar", "Baz"], rows[1]
  end

  def test_column_without_r_hash
    @sheet = File.read("test/files/column-without-r.xml")

    rows = []

    collector = proc do |row|
      rows << row
    end

    handler = Xsv::SheetRowsHandler.new(:hash, {"Some strings" => "", "Foo" => ""}, @workbook, 0, 6, &collector)
    handler.parse(@sheet)

    assert_equal({"Some strings" => "Bar", "Foo" => "Baz"}, rows[0])
  end
end
