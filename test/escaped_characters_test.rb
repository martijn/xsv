require "./test/test_helper"

# A character that cannot be written in XML is escaped as _xHHHH_, such as _x000D_ for a carriage return
class EscapedCharactersTest < Minitest::Test
  include Xsv::Helpers

  def test_shared_strings
    strings = Xsv::SharedStringsParser.parse(File.open("test/files/sharedStrings-escaped.xml"))

    assert_equal ["Line 1\r\nLine 2", "Bell\a", "_x000D_ is a carriage return", "Rich\r\ntext"], strings
  end

  def test_inline_and_formula_strings
    workbook = Xsv.open("test/files/excel2016.xlsx")
    rows = []
    Xsv::SheetRowsHandler.new(:array, nil, [nil] * 3, workbook, 0, 99) { |row| rows << row }
      .parse(File.read("test/files/escaped-characters.xml"))

    assert_equal [["Line 1\r\nLine 2", "Bell\a", "Smile 😀 and _x000D_"]], rows
  end

  def test_unescape_characters
    assert_equal "a\rb", unescape_characters("a_x000D_b")
    assert_equal "a_x000D_b", unescape_characters("a_x005F_x000D_b")
    assert_equal "😀", unescape_characters("_xD83D__xDE00_")
    assert_equal "_xD83D_", unescape_characters("_xD83D_")
    assert_equal "_x00_ and _xGHIJ_", unescape_characters("_x00_ and _xGHIJ_")
  end
end
