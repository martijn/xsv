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
    handler = Xsv::SheetRowsHandler.new(:array, nil, empty_row, @workbook, 0, 99999) do |row|
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
    handler = Xsv::SheetRowsHandler.new(:hash, empty_row.keys, empty_row, @workbook, 0, 99999) do |row|
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
      handler = Xsv::SheetRowsHandler.new(:array, nil, ([nil] * 10), @workbook, row_skip, 6, &collector)
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

    handler = Xsv::SheetRowsHandler.new(:array, nil, ([nil] * 10), @workbook, 0, 6, &collector)
    handler.parse(@sheet)

    assert_equal "This is Text", rows[0][0]
  end

  def test_special_types
    rows = []
    handler = Xsv::SheetRowsHandler.new(:array, nil, [], @workbook, 0, 99999) do |row|
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
    handler = Xsv::SheetRowsHandler.new(:array, nil, [], @workbook, 0, 99999) {}

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

    handler = Xsv::SheetRowsHandler.new(:array, [], ([nil] * 2), @workbook, 0, 6, &collector)
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

    empty_row = {"Some strings" => "", "Foo" => ""}
    handler = Xsv::SheetRowsHandler.new(:hash, empty_row.keys, empty_row, @workbook, 0, 6, &collector)
    handler.parse(@sheet)

    assert_equal({"Some strings" => "Bar", "Foo" => "Baz"}, rows[0])
  end

  def test_row_without_r_attribute
    @sheet = File.read("test/files/row-without-r.xml")

    rows = []

    collector = proc do |row|
      rows << row
    end

    # Test array mode
    handler = Xsv::SheetRowsHandler.new(:array, nil, ([nil] * 2), @workbook, 0, 6, &collector)
    handler.parse(@sheet)

    assert_equal 3, rows.length, "Should parse all 3 rows even when r attribute is missing"
    assert_equal "Row1Col1", rows[0][0]
    assert_equal "Row1Col2", rows[0][1]
    assert_equal "Row2Col1", rows[1][0]
    assert_equal "Row2Col2", rows[1][1]
    assert_equal "Row3Col1", rows[2][0]
    assert_equal "Row3Col2", rows[2][1]
  end

  def test_row_without_r_attribute_with_row_skip
    @sheet = File.read("test/files/row-without-r.xml")

    rows = []

    collector = proc do |row|
      rows << row
    end

    # Test with row_skip = 1 (skip first row)
    handler = Xsv::SheetRowsHandler.new(:array, nil, ([nil] * 2), @workbook, 1, 6, &collector)
    handler.parse(@sheet)

    assert_equal 2, rows.length, "Should skip first row and parse remaining 2 rows"
    assert_equal "Row2Col1", rows[0][0]
    assert_equal "Row2Col2", rows[0][1]
    assert_equal "Row3Col1", rows[1][0]
    assert_equal "Row3Col2", rows[1][1]
  end

  # IO that returns the XML in chunks of a fixed number of bytes
  class ChunkedIO
    def initialize(string, size)
      @chunks = string.b.scan(/.{1,#{size}}/mn)
    end

    def sysread(_size)
      @chunks.shift or raise EOFError
    end
  end

  SCANNER_XML = <<~XML
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <x:worksheet xmlns:x="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><x:sheetData>
    <x:row r="1"><x:c r="A1" t="inlineStr"><x:is><x:t>Zürich &amp; 😀</x:t></x:is></x:c><x:c r="C1" t="b"><x:v>1</x:v></x:c></x:row>
    <row r="3" spans="1:3"><c r="A3" s="0"/><c r="B3"><v>4.5</v></c><c r="C3" t="s"><v>0</v></c></row>
    <row r="4"/>
    <row><c><v>7</v></c><c t="str"><f>A5</f><v> é </v></c></row>
    </x:sheetData></x:worksheet>
  XML

  def test_scanner
    expected = [
      ["Zürich & 😀", nil, true],
      [nil, nil, nil],
      [nil, 4.5, "Some strings"],
      [nil, nil, nil],
      [7, "é", nil]
    ]

    rows = []
    Xsv::SheetRowsHandler.new(:array, nil, [nil] * 3, @workbook, 0, 99) { |row| rows << row }.parse(SCANNER_XML)

    assert_equal expected, rows

    # Rows split across chunks of any size are parsed again after reading more data
    (1..8).each do |size|
      rows = []
      Xsv::SheetRowsHandler.new(:array, nil, [nil] * 3, @workbook, 0, 99) { |row| rows << row }.parse(ChunkedIO.new(SCANNER_XML, size))

      assert_equal expected, rows, "chunk size #{size}"
    end
  end

  def test_scanner_truncated_document
    assert_raises Xsv::Error do
      Xsv::SheetRowsHandler.new(:array, nil, [nil] * 3, @workbook, 0, 99) {}.parse(SCANNER_XML[0, 200])
    end
  end
end
