require "./test/test_helper"

# Inline strings and the text of formulas keep their leading and trailing whitespace, as shared strings do
class StringWhitespaceTest < Minitest::Test
  def test_string_whitespace
    workbook = Xsv.open("test/files/excel2016.xlsx")
    rows = []
    Xsv::SheetRowsHandler.new(:array, nil, [nil] * 5, workbook, 0, 99) { |row| rows << row }
      .parse(File.read("test/files/string-whitespace.xml"))

    assert_equal [
      ["  Leading", "Trailing  ", " padded ", "Indented XML", "Rich text"],
      # An empty t element that closes itself reads no text, nor the text after it
      [nil, "ab", true, nil, nil]
    ], rows
  end
end
